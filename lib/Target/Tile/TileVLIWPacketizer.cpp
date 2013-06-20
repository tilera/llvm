//===--- TileVLIWPacketizer.cpp - VLIW Packetizer -----------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "packets"

#include "Tile.h"
#include "TileInstrInfo.h"
#include "llvm/CodeGen/DFAPacketizer.h"
#include "llvm/CodeGen/MachineDominators.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineLoopInfo.h"
#include "llvm/CodeGen/ScheduleDAG.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetInstrInfo.h"
#include "llvm/MC/MCInstrItineraries.h"

using namespace llvm;
using namespace TileII;

namespace {
class TileVLIWPacketizer : public MachineFunctionPass {

public:
  static char ID;
  TileVLIWPacketizer() : MachineFunctionPass(ID) {}

  void getAnalysisUsage(AnalysisUsage &AU) const {
    AU.setPreservesCFG();
    AU.addRequired<MachineDominatorTree>();
    AU.addPreserved<MachineDominatorTree>();
    AU.addRequired<MachineLoopInfo>();
    AU.addPreserved<MachineLoopInfo>();
    MachineFunctionPass::getAnalysisUsage(AU);
  }

  const char *getPassName() const { return "Tile VLIW Packetizer"; }

  bool runOnMachineFunction(MachineFunction &Fn);
};
char TileVLIWPacketizer::ID = 0;

class TileVLIWPacketizerList : public VLIWPacketizerList {

public:
  // Ctor.
  TileVLIWPacketizerList(MachineFunction &MF, MachineLoopInfo &MLI,
                         MachineDominatorTree &MDT);

  // Initialize some internal flags.
  virtual void initPacketizerState(void);

  // Ignore bundling of pseudo instructions.
  virtual bool ignorePseudoInstruction(MachineInstr *MI,
                                       MachineBasicBlock *MBB);

  // Check for self-packet.
  virtual bool isSoloInstruction(MachineInstr *MI);

  // Is it legal to packetize SUI and SUJ together.
  virtual bool isLegalToPacketizeTogether(SUnit *SUI, SUnit *SUJ);

  // Do a second check to see if MI can be bundled into current
  // packet in either X or Y mode.
  //
  // The original DFA packetizer do not support multi func unit
  // occupation, while for Tile, one instruction which issued
  // at X1 slot actually occupy physical pipe1 and pipe2.
  //
  // In TileSchedule.td, we pretend X1 only occupy pipe1 to make
  // the DFA machine happy, we do a second check here to make sure
  // the instruction is correctly bundled.
  bool isLegalToTileGXXYMode(MachineInstr *MI);

  // Is it legal to prune dependece between SUI and SUJ.
  virtual bool isLegalToPruneDependencies(SUnit *SUI, SUnit *SUJ);

private:
  // Return true if the instruction is a direct jump.
  bool isDirectJump(const MachineInstr *MI) const;

  // Return TileType of MI.
  TileIssueType TileIssueTypeOf(const MachineInstr *MI) const;

  bool isPipe2Conflict(const MachineInstr *MI) const;
  bool isPipe2Conflict(const MachineInstr *MI0, const MachineInstr *MI1,
                       const MachineInstr *MI) const;
};
}

TileVLIWPacketizerList::TileVLIWPacketizerList(
    MachineFunction &MF, MachineLoopInfo &MLI, MachineDominatorTree &MDT)
    : VLIWPacketizerList(MF, MLI, MDT, true) {}

bool TileVLIWPacketizer::runOnMachineFunction(MachineFunction &Fn) {
  const TargetInstrInfo *TII = Fn.getTarget().getInstrInfo();
  MachineLoopInfo &MLI = getAnalysis<MachineLoopInfo>();
  MachineDominatorTree &MDT = getAnalysis<MachineDominatorTree>();

  // Instantiate the packetizer.
  TileVLIWPacketizerList Packetizer(Fn, MLI, MDT);

  // DFA state table should not be empty.
  assert(Packetizer.getResourceTracker() && "Empty DFA table!");

  // Loop over all of the basic blocks.
  for (MachineFunction::iterator MBB = Fn.begin(), MBBe = Fn.end(); MBB != MBBe;
       ++MBB) {
    // Find scheduling regions and schedule / packetize each region.
    for (MachineBasicBlock::iterator RegionEnd = MBB->end(),
                                     MBBb = MBB->begin();
         RegionEnd != MBBb;) {
      // The next region starts above the previous region. Look backward in the
      // instruction stream until we find the nearest boundary.
      MachineBasicBlock::iterator I = RegionEnd;
      for (; I != MBBb; --I) {
        if (TII->isSchedulingBoundary(llvm::prior(I), MBB, Fn))
          break;
      }

      // Skip empty regions and regions with one instruction.
      MachineBasicBlock::iterator priorEnd = llvm::prior(RegionEnd);
      if (I == RegionEnd || I == priorEnd) {
        RegionEnd = priorEnd;
        continue;
      }

      Packetizer.PacketizeMIs(MBB, I, RegionEnd);
      RegionEnd = I;
    }
  }

  return true;
}

void TileVLIWPacketizerList::initPacketizerState() {
  return;
}

bool TileVLIWPacketizerList::ignorePseudoInstruction(MachineInstr *MI,
                                                     MachineBasicBlock *MBB) {

  if (MI->isDebugValue())
    return true;

  // We must print out inline assembly.
  if (MI->isInlineAsm())
    return false;

  // We check if MI has any functional units mapped to it.
  // If it doesn't, we ignore the instruction.
  const MCInstrDesc &TID = MI->getDesc();
  unsigned SchedClass = TID.getSchedClass();
  const InstrStage *IS =
      ResourceTracker->getInstrItins()->beginStage(SchedClass);
  unsigned FuncUnits = IS->getUnits();
  return !FuncUnits;
}

bool TileVLIWPacketizerList::isSoloInstruction(MachineInstr *MI) {
  const uint64_t F = MI->getDesc().TSFlags;
  return ((F >> SoloPos) & SoloMask);
}

bool TileVLIWPacketizerList::isLegalToTileGXXYMode(MachineInstr *MI) {
  MachineInstr *MI0, *MI1;
  TileIssueType T = TileIssueTypeOf(MI);

  switch (CurrentPacketMIs.size()) {
  case 0:
    llvm_unreachable("isLegalToTileGXXYMode shouldn't reach here!");
  case 1:
    if (!(T == IT_X1Y2 || T == IT_X1))
      return true;
    MI0 = CurrentPacketMIs[0];
    return !isPipe2Conflict(MI0);
  case 2:
    MI0 = CurrentPacketMIs[0];
    MI1 = CurrentPacketMIs[1];
    return !isPipe2Conflict(MI0, MI1, MI);
  default:
    llvm_unreachable("3 pipelines can't execute more than 3 instructions!");
  }
}

// SUI is the current instruction that is out side of the current packet.
// SUJ is the current instruction inside the current packet against which that
// SUI will be packetized.
bool TileVLIWPacketizerList::isLegalToPacketizeTogether(SUnit *SUI,
                                                        SUnit *SUJ) {
  MachineInstr *I = SUI->getInstr();
  MachineInstr *J = SUJ->getInstr();
  assert(I && J && "Unable to packetize null instruction!");
  assert(!isSoloInstruction(I) && !ignorePseudoInstruction(I, I->getParent()) &&
         "Something gone wrong with packetizer mechanism!");

  if (!isLegalToTileGXXYMode(I))
    return false;

  const MCInstrDesc &MCIDI = I->getDesc();
  const MCInstrDesc &MCIDJ = J->getDesc();

  if (!SUJ->isSucc(SUI))
    return true;

  for (unsigned i = 0, e = SUJ->Succs.size(); i != e; ++i) {
    if (SUJ->Succs[i].getSUnit() != SUI) {
      continue;
    }

    SDep Dep = SUJ->Succs[i];
    SDep::Kind DepType = Dep.getKind();
    unsigned DepReg = 0;
    if (DepType != SDep::Order) {
      DepReg = Dep.getReg();
    }

    if ((MCIDI.isCall() || MCIDI.isReturn()) && DepType == SDep::Order) {
      // do nothing
    } else if (isDirectJump(I) && !MCIDJ.isBranch() && !MCIDJ.isCall() &&
               (DepType == SDep::Order)) {
      // Ignore Order dependences between unconditional direct branches
      // and non-control-flow instructions.
      // do nothing
    } else if (MCIDI.isConditionalBranch() && (DepType != SDep::Data) &&
               (DepType != SDep::Output)) {
      // Ignore all dependences for jumps except for true and output
      // dependences.
      // do nothing
    } else if (DepType == SDep::Output && DepReg != Tile::ZERO) {
      // zero-reg can be targeted by multiple instructions.
      return false;
    } else if (DepType == SDep::Order && Dep.isArtificial()) {
      // Ignore artificial dependencies.
      // do nothing
    } else if (DepType != SDep::Anti) {
      // Skip over anti-dependences. Two instructions that are
      // anti-dependent can share a packet.
      return false;
    }
  }

  return true;
}

bool TileVLIWPacketizerList::isLegalToPruneDependencies(SUnit *SUI,
                                                        SUnit *SUJ) {
  MachineInstr *I = SUI->getInstr();
  assert(I && SUJ->getInstr() && "Unable to packetize null instruction!");

  //FIXME:: needs tuning here.
  return false;
}

//===----------------------------------------------------------------------===//
//                         Private Helper Functions
//===----------------------------------------------------------------------===//

bool TileVLIWPacketizerList::isDirectJump(const MachineInstr *MI) const {
  return (MI->getOpcode() == Tile::J);
}

TileIssueType
TileVLIWPacketizerList::TileIssueTypeOf(const MachineInstr *MI) const {
  const uint64_t F = MI->getDesc().TSFlags;
  return (TileIssueType)((F >> IssueTypePos) & IssueTypeMask);
}

bool TileVLIWPacketizerList::isPipe2Conflict(const MachineInstr *MI) const {
  TileIssueType T = TileIssueTypeOf(MI);
  return T == IT_X1 || T == IT_X1Y2;
}

bool TileVLIWPacketizerList::isPipe2Conflict(const MachineInstr *MI0,
                                             const MachineInstr *MI1,
                                             const MachineInstr *MI) const {
  TileIssueType T = TileIssueTypeOf(MI);
  TileIssueType T0 = TileIssueTypeOf(MI0);
  TileIssueType T1 = TileIssueTypeOf(MI1);
  unsigned count = 0;
  if (T == IT_X0X1Y0Y1)
    count++;
  else if (T == IT_X1 || T == IT_X0)
    return true;
  if (T0 == IT_X0X1Y0Y1)
    count++;
  else if (T0 == IT_X1 || T0 == IT_X0)
    return true;
  if (T1 == IT_X0X1Y0Y1)
    count++;
  else if (T1 == IT_X1 || T1 == IT_X0)
    return true;
  return count != 2;
}

//===----------------------------------------------------------------------===//
//                         Public Constructor Functions
//===----------------------------------------------------------------------===//

FunctionPass *llvm::createTileVLIWPacketizer() {
  return new TileVLIWPacketizer();
}
