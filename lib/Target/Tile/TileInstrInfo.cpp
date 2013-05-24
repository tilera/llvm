//===-- TileInstrInfo.cpp - Tile Instruction Information ------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the Tile implementation of the TargetInstrInfo class.
//
//===----------------------------------------------------------------------===//

#include "TileInstrInfo.h"
#include "TileTargetMachine.h"
#include "TileMachineFunction.h"
#include "InstPrinter/TileInstPrinter.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/TargetRegistry.h"
#include "llvm/ADT/STLExtras.h"

#define GET_INSTRINFO_CTOR
#include "TileGenInstrInfo.inc"
#include "TileGenDFAPacketizer.inc"

using namespace llvm;

TileInstrInfo::TileInstrInfo(TileTargetMachine &tm)
    : TileGenInstrInfo(Tile::ADJCALLSTACKDOWN, Tile::ADJCALLSTACKUP), TM(tm),
      RI(*TM.getSubtargetImpl(), *this), UncondBrOpc(Tile::J) {}

const TileRegisterInfo &TileInstrInfo::getRegisterInfo() const { return RI; }

unsigned TileInstrInfo::isLoadFromStackSlot(const MachineInstr *MI,
                                            int &FrameIndex) const {
  return 0;
}

unsigned TileInstrInfo::isStoreToStackSlot(const MachineInstr *MI,
                                           int &FrameIndex) const {
  return 0;
}

void TileInstrInfo::copyPhysReg(
    MachineBasicBlock &MBB, MachineBasicBlock::iterator I, DebugLoc DL,
    unsigned DestReg, unsigned SrcReg, bool KillSrc) const {
  unsigned Opc = 0, ZeroReg = 0;

  if (Tile::CPURegsRegClass.contains(DestReg)) {
    if (Tile::CPURegsRegClass.contains(SrcReg))
      Opc = Tile::ADD, ZeroReg = Tile::ZERO;
    else
      abort();
  }

  if (Tile::CPU32RegsRegClass.contains(DestReg)) {
    if (Tile::CPU32RegsRegClass.contains(SrcReg))
      Opc = Tile::ADDX, ZeroReg = Tile::ZERO_32;
    else
      abort();
  }

  assert(Opc && "Cannot copy registers");

  MachineInstrBuilder MIB = BuildMI(MBB, I, DL, get(Opc));

  if (DestReg)
    MIB.addReg(DestReg, RegState::Define);

  if (ZeroReg)
    MIB.addReg(ZeroReg);

  if (SrcReg)
    MIB.addReg(SrcReg, getKillRegState(KillSrc));
}

void TileInstrInfo::storeRegToStackSlot(
    MachineBasicBlock &MBB, MachineBasicBlock::iterator I, unsigned SrcReg,
    bool isKill, int FI, const TargetRegisterClass *RC,
    const TargetRegisterInfo *TRI) const {
  DebugLoc DL;
  if (I != MBB.end())
    DL = I->getDebugLoc();

  unsigned Opc = 0;

  if (RC == &Tile::CPURegsRegClass || RC == &Tile::SIMDRegsRegClass)
    Opc = Tile::ST;
  else if (RC == &Tile::CPU32RegsRegClass)
    Opc = Tile::ST4;

  assert(Opc && "Register class not handled!");
  BuildMI(MBB, I, DL, get(Opc)).addFrameIndex(FI)
      .addReg(SrcReg, getKillRegState(isKill));
}

void TileInstrInfo::loadRegFromStackSlot(
    MachineBasicBlock &MBB, MachineBasicBlock::iterator I, unsigned DestReg,
    int FI, const TargetRegisterClass *RC,
    const TargetRegisterInfo *TRI) const {
  DebugLoc DL;
  if (I != MBB.end())
    DL = I->getDebugLoc();
  unsigned Opc = 0;

  if (RC == &Tile::CPURegsRegClass || RC == &Tile::SIMDRegsRegClass)
    Opc = Tile::LD;
  else if (RC == &Tile::CPU32RegsRegClass)
    Opc = Tile::LD4S32;

  assert(Opc && "Register class not handled!");
  BuildMI(MBB, I, DL, get(Opc), DestReg).addFrameIndex(FI);
}

MachineInstr *TileInstrInfo::emitFrameIndexDebugValue(
    MachineFunction &MF, int FrameIx, uint64_t Offset, const MDNode *MDPtr,
    DebugLoc DL) const {
  MachineInstrBuilder MIB = BuildMI(MF, DL, get(Tile::DBG_VALUE))
      .addFrameIndex(FrameIx).addImm(0).addImm(Offset).addMetadata(MDPtr);
  return &*MIB;
}

//===----------------------------------------------------------------------===//
// Branch Analysis.
//===----------------------------------------------------------------------===//

static unsigned GetAnalyzableBrOpc(unsigned Opc) {
  return (Opc == Tile::BEQZ || Opc == Tile::BEQZ32 || Opc == Tile::BNEZ ||
          Opc == Tile::BNEZ32 || Opc == Tile::BGTZ || Opc == Tile::BGTZ32 ||
          Opc == Tile::BGEZ || Opc == Tile::BGEZ32 || Opc == Tile::BLTZ ||
          Opc == Tile::BLTZ32 || Opc == Tile::BLEZ || Opc == Tile::BLEZ32 ||
          Opc == Tile::J)
             ? Opc
             : 0;
}

unsigned Tile::GetOppositeBranchOpc(unsigned Opc) {
  switch (Opc) {
  default:
    llvm_unreachable("Illegal opcode!");
  case Tile::BEQZ:
    return Tile::BNEZ;
  case Tile::BNEZ:
    return Tile::BEQZ;
  case Tile::BGTZ:
    return Tile::BLEZ;
  case Tile::BGEZ:
    return Tile::BLTZ;
  case Tile::BLTZ:
    return Tile::BGEZ;
  case Tile::BLEZ:
    return Tile::BGTZ;
  case Tile::BEQZ32:
    return Tile::BNEZ32;
  case Tile::BNEZ32:
    return Tile::BEQZ32;
  case Tile::BGTZ32:
    return Tile::BLEZ32;
  case Tile::BGEZ32:
    return Tile::BLTZ32;
  case Tile::BLTZ32:
    return Tile::BGEZ32;
  case Tile::BLEZ32:
    return Tile::BGTZ32;
  }
}

static void
analyzeCondBr(const MachineInstr *Inst, unsigned Opc, MachineBasicBlock *&BB,
              SmallVectorImpl<MachineOperand> &Cond) {
  assert(GetAnalyzableBrOpc(Opc) && "Not an analyzable branch");
  int NumOp = Inst->getNumExplicitOperands();

  // For both int and fp branches, the last explicit operand is the MBB.
  BB = Inst->getOperand(NumOp - 1).getMBB();
  Cond.push_back(MachineOperand::CreateImm(Opc));

  for (int i = 0; i < NumOp - 1; i++)
    Cond.push_back(Inst->getOperand(i));
}

bool TileInstrInfo::AnalyzeBranch(
    MachineBasicBlock &MBB, MachineBasicBlock *&TBB, MachineBasicBlock *&FBB,
    SmallVectorImpl<MachineOperand> &Cond, bool AllowModify) const {
  MachineBasicBlock::reverse_iterator I = MBB.rbegin(), REnd = MBB.rend();

  // Skip all the debug instructions.
  while (I != REnd && I->isDebugValue())
    ++I;

  if (I == REnd || !isUnpredicatedTerminator(&*I)) {
    // If this block ends with no branches (it just falls through to its succ)
    // just return false, leaving TBB/FBB null.
    TBB = FBB = NULL;
    return false;
  }

  MachineInstr *LastInst = &*I;
  unsigned LastOpc = LastInst->getOpcode();

  // Not an analyzable branch (must be an indirect jump).
  if (!GetAnalyzableBrOpc(LastOpc))
    return true;

  // Get the second to last instruction in the block.
  unsigned SecondLastOpc = 0;
  MachineInstr *SecondLastInst = NULL;

  if (++I != REnd) {
    SecondLastInst = &*I;
    SecondLastOpc = GetAnalyzableBrOpc(SecondLastInst->getOpcode());

    // Not an analyzable branch (must be an indirect jump).
    if (isUnpredicatedTerminator(SecondLastInst) && !SecondLastOpc)
      return true;
  }

  // If there is only one terminator instruction, process it.
  if (!SecondLastOpc) {
    // Unconditional branch.
    if (LastOpc == UncondBrOpc) {
      TBB = LastInst->getOperand(0).getMBB();
      return false;
    }

    // Conditional branch.
    analyzeCondBr(LastInst, LastOpc, TBB, Cond);
    return false;
  }

  // If we reached here, there are two branches.
  // If there are three terminators, we don't know what sort of block this is.
  if (++I != REnd && isUnpredicatedTerminator(&*I))
    return true;

  // If second to last instruction is an unconditional branch,
  // analyze it and remove the last instruction.
  if (SecondLastOpc == UncondBrOpc) {
    // Return if the last instruction cannot be removed.
    if (!AllowModify)
      return true;

    TBB = SecondLastInst->getOperand(0).getMBB();
    LastInst->eraseFromParent();
    return false;
  }

  // Conditional branch followed by an unconditional branch.
  // The last one must be unconditional.
  if (LastOpc != UncondBrOpc)
    return true;

  analyzeCondBr(SecondLastInst, SecondLastOpc, TBB, Cond);
  FBB = LastInst->getOperand(0).getMBB();

  return false;
}

void TileInstrInfo::BuildCondBr(
    MachineBasicBlock &MBB, MachineBasicBlock *TBB, DebugLoc DL,
    const SmallVectorImpl<MachineOperand> &Cond) const {
  unsigned Opc = Cond[0].getImm();
  const MCInstrDesc &MCID = get(Opc);
  MachineInstrBuilder MIB = BuildMI(&MBB, DL, MCID);

  for (unsigned i = 1, e = Cond.size(); i != e; ++i)
    MIB.addReg(Cond[i].getReg());

  MIB.addMBB(TBB);
}

unsigned TileInstrInfo::InsertBranch(
    MachineBasicBlock &MBB, MachineBasicBlock *TBB, MachineBasicBlock *FBB,
    const SmallVectorImpl<MachineOperand> &Cond, DebugLoc DL) const {
  // Shouldn't be a fall through.
  assert(TBB && "InsertBranch must not be told to insert a fallthrough");

  // # of condition operands:
  //  Unconditional branches: 0
  //  Floating point branches: 1 (opc)
  //  Int BranchZero: 2 (opc, reg)
  //  Int Branch: 3 (opc, reg0, reg1)
  assert((Cond.size() <= 3) && "# of Tile branch conditions must be <= 3!");

  // Two-way Conditional branch.
  if (FBB) {
    BuildCondBr(MBB, TBB, DL, Cond);
    BuildMI(&MBB, DL, get(UncondBrOpc)).addMBB(FBB);
    return 2;
  }

  // One way branch.
  // Unconditional branch.
  if (Cond.empty())
    BuildMI(&MBB, DL, get(UncondBrOpc)).addMBB(TBB);
  else // Conditional branch.
    BuildCondBr(MBB, TBB, DL, Cond);
  return 1;
}

unsigned TileInstrInfo::RemoveBranch(MachineBasicBlock &MBB) const {
  MachineBasicBlock::reverse_iterator I = MBB.rbegin(), REnd = MBB.rend();
  MachineBasicBlock::reverse_iterator FirstBr;
  unsigned removed;

  // Skip all the debug instructions.
  while (I != REnd && I->isDebugValue())
    ++I;

  FirstBr = I;

  // Up to 2 branches are removed.
  // Note that indirect branches are not removed.
  for (removed = 0; I != REnd && removed < 2; ++I, ++removed)
    if (!GetAnalyzableBrOpc(I->getOpcode()))
      break;

  MBB.erase(I.base(), FirstBr.base());

  return removed;
}

// Return the inverse opcode of the specified Branch instruction.
bool TileInstrInfo::ReverseBranchCondition(
    SmallVectorImpl<MachineOperand> &Cond) const {
  assert((Cond.size() && Cond.size() <= 3) && "Invalid Tile branch condition!");
  Cond[0].setImm(Tile::GetOppositeBranchOpc(Cond[0].getImm()));
  return false;
}

DFAPacketizer *TileInstrInfo::CreateTargetScheduleState(
    const TargetMachine *TM, const ScheduleDAG *DAG) const {
  const InstrItineraryData *II = TM->getInstrItineraryData();
  return TM->getSubtarget<TileGenSubtargetInfo>().createDFAPacketizer(II);
}

bool TileInstrInfo::isSchedulingBoundary(const MachineInstr *MI,
                                         const MachineBasicBlock *MBB,
                                         const MachineFunction &MF) const {
  // Debug info is never a scheduling boundary. It's necessary to be explicit
  // due to the special treatment of IT instructions below, otherwise a
  // dbg_value followed by an IT will result in the IT instruction being
  // considered a scheduling hazard, which is wrong. It should be the actual
  // instruction preceding the dbg_value instruction(s), just like it is
  // when debug info is not present.
  if (MI->isDebugValue())
    return false;

  // Terminators and labels can't be scheduled around.
  if (MI->getDesc().isTerminator() || MI->getDesc().isCall() || MI->isLabel() ||
      MI->isInlineAsm())
    return true;

  return false;
}
