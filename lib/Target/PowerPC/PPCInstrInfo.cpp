//===-- PPCInstrInfo.cpp - PowerPC Instruction Information ----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the PowerPC implementation of the TargetInstrInfo class.
//
//===----------------------------------------------------------------------===//

#include "PPCInstrInfo.h"
#include "MCTargetDesc/PPCPredicates.h"
#include "PPC.h"
#include "PPCHazardRecognizers.h"
#include "PPCInstrBuilder.h"
#include "PPCMachineFunctionInfo.h"
#include "PPCTargetMachine.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineMemOperand.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/PseudoSourceValue.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/TargetRegistry.h"
#include "llvm/Support/raw_ostream.h"

#define GET_INSTRINFO_CTOR
#include "PPCGenInstrInfo.inc"

using namespace llvm;

static cl::
opt<bool> DisableCTRLoopAnal("disable-ppc-ctrloop-analysis", cl::Hidden,
            cl::desc("Disable analysis for CTR loops"));

PPCInstrInfo::PPCInstrInfo(PPCTargetMachine &tm)
  : PPCGenInstrInfo(PPC::ADJCALLSTACKDOWN, PPC::ADJCALLSTACKUP),
    TM(tm), RI(*TM.getSubtargetImpl(), *this) {}

/// CreateTargetHazardRecognizer - Return the hazard recognizer to use for
/// this target when scheduling the DAG.
ScheduleHazardRecognizer *PPCInstrInfo::CreateTargetHazardRecognizer(
  const TargetMachine *TM,
  const ScheduleDAG *DAG) const {
  unsigned Directive = TM->getSubtarget<PPCSubtarget>().getDarwinDirective();
  if (Directive == PPC::DIR_440 || Directive == PPC::DIR_A2 ||
      Directive == PPC::DIR_E500mc || Directive == PPC::DIR_E5500) {
    const InstrItineraryData *II = TM->getInstrItineraryData();
    return new PPCScoreboardHazardRecognizer(II, DAG);
  }

  return TargetInstrInfo::CreateTargetHazardRecognizer(TM, DAG);
}

/// CreateTargetPostRAHazardRecognizer - Return the postRA hazard recognizer
/// to use for this target when scheduling the DAG.
ScheduleHazardRecognizer *PPCInstrInfo::CreateTargetPostRAHazardRecognizer(
  const InstrItineraryData *II,
  const ScheduleDAG *DAG) const {
  unsigned Directive = TM.getSubtarget<PPCSubtarget>().getDarwinDirective();

  // Most subtargets use a PPC970 recognizer.
  if (Directive != PPC::DIR_440 && Directive != PPC::DIR_A2 &&
      Directive != PPC::DIR_E500mc && Directive != PPC::DIR_E5500) {
    const TargetInstrInfo *TII = TM.getInstrInfo();
    assert(TII && "No InstrInfo?");

    return new PPCHazardRecognizer970(*TII);
  }

  return new PPCScoreboardHazardRecognizer(II, DAG);
}

// Detect 32 -> 64-bit extensions where we may reuse the low sub-register.
bool PPCInstrInfo::isCoalescableExtInstr(const MachineInstr &MI,
                                         unsigned &SrcReg, unsigned &DstReg,
                                         unsigned &SubIdx) const {
  switch (MI.getOpcode()) {
  default: return false;
  case PPC::EXTSW:
  case PPC::EXTSW_32_64:
    SrcReg = MI.getOperand(1).getReg();
    DstReg = MI.getOperand(0).getReg();
    SubIdx = PPC::sub_32;
    return true;
  }
}

unsigned PPCInstrInfo::isLoadFromStackSlot(const MachineInstr *MI,
                                           int &FrameIndex) const {
  // Note: This list must be kept consistent with LoadRegFromStackSlot.
  switch (MI->getOpcode()) {
  default: break;
  case PPC::LD:
  case PPC::LWZ:
  case PPC::LFS:
  case PPC::LFD:
  case PPC::RESTORE_CR:
  case PPC::LVX:
  case PPC::RESTORE_VRSAVE:
    // Check for the operands added by addFrameReference (the immediate is the
    // offset which defaults to 0).
    if (MI->getOperand(1).isImm() && !MI->getOperand(1).getImm() &&
        MI->getOperand(2).isFI()) {
      FrameIndex = MI->getOperand(2).getIndex();
      return MI->getOperand(0).getReg();
    }
    break;
  }
  return 0;
}

unsigned PPCInstrInfo::isStoreToStackSlot(const MachineInstr *MI,
                                          int &FrameIndex) const {
  // Note: This list must be kept consistent with StoreRegToStackSlot.
  switch (MI->getOpcode()) {
  default: break;
  case PPC::STD:
  case PPC::STW:
  case PPC::STFS:
  case PPC::STFD:
  case PPC::SPILL_CR:
  case PPC::STVX:
  case PPC::SPILL_VRSAVE:
    // Check for the operands added by addFrameReference (the immediate is the
    // offset which defaults to 0).
    if (MI->getOperand(1).isImm() && !MI->getOperand(1).getImm() &&
        MI->getOperand(2).isFI()) {
      FrameIndex = MI->getOperand(2).getIndex();
      return MI->getOperand(0).getReg();
    }
    break;
  }
  return 0;
}

// commuteInstruction - We can commute rlwimi instructions, but only if the
// rotate amt is zero.  We also have to munge the immediates a bit.
MachineInstr *
PPCInstrInfo::commuteInstruction(MachineInstr *MI, bool NewMI) const {
  MachineFunction &MF = *MI->getParent()->getParent();

  // Normal instructions can be commuted the obvious way.
  if (MI->getOpcode() != PPC::RLWIMI)
    return TargetInstrInfo::commuteInstruction(MI, NewMI);

  // Cannot commute if it has a non-zero rotate count.
  if (MI->getOperand(3).getImm() != 0)
    return 0;

  // If we have a zero rotate count, we have:
  //   M = mask(MB,ME)
  //   Op0 = (Op1 & ~M) | (Op2 & M)
  // Change this to:
  //   M = mask((ME+1)&31, (MB-1)&31)
  //   Op0 = (Op2 & ~M) | (Op1 & M)

  // Swap op1/op2
  unsigned Reg0 = MI->getOperand(0).getReg();
  unsigned Reg1 = MI->getOperand(1).getReg();
  unsigned Reg2 = MI->getOperand(2).getReg();
  bool Reg1IsKill = MI->getOperand(1).isKill();
  bool Reg2IsKill = MI->getOperand(2).isKill();
  bool ChangeReg0 = false;
  // If machine instrs are no longer in two-address forms, update
  // destination register as well.
  if (Reg0 == Reg1) {
    // Must be two address instruction!
    assert(MI->getDesc().getOperandConstraint(0, MCOI::TIED_TO) &&
           "Expecting a two-address instruction!");
    Reg2IsKill = false;
    ChangeReg0 = true;
  }

  // Masks.
  unsigned MB = MI->getOperand(4).getImm();
  unsigned ME = MI->getOperand(5).getImm();

  if (NewMI) {
    // Create a new instruction.
    unsigned Reg0 = ChangeReg0 ? Reg2 : MI->getOperand(0).getReg();
    bool Reg0IsDead = MI->getOperand(0).isDead();
    return BuildMI(MF, MI->getDebugLoc(), MI->getDesc())
      .addReg(Reg0, RegState::Define | getDeadRegState(Reg0IsDead))
      .addReg(Reg2, getKillRegState(Reg2IsKill))
      .addReg(Reg1, getKillRegState(Reg1IsKill))
      .addImm((ME+1) & 31)
      .addImm((MB-1) & 31);
  }

  if (ChangeReg0)
    MI->getOperand(0).setReg(Reg2);
  MI->getOperand(2).setReg(Reg1);
  MI->getOperand(1).setReg(Reg2);
  MI->getOperand(2).setIsKill(Reg1IsKill);
  MI->getOperand(1).setIsKill(Reg2IsKill);

  // Swap the mask around.
  MI->getOperand(4).setImm((ME+1) & 31);
  MI->getOperand(5).setImm((MB-1) & 31);
  return MI;
}

void PPCInstrInfo::insertNoop(MachineBasicBlock &MBB,
                              MachineBasicBlock::iterator MI) const {
  DebugLoc DL;
  BuildMI(MBB, MI, DL, get(PPC::NOP));
}


// Branch analysis.
// Note: If the condition register is set to CTR or CTR8 then this is a
// BDNZ (imm == 1) or BDZ (imm == 0) branch.
bool PPCInstrInfo::AnalyzeBranch(MachineBasicBlock &MBB,MachineBasicBlock *&TBB,
                                 MachineBasicBlock *&FBB,
                                 SmallVectorImpl<MachineOperand> &Cond,
                                 bool AllowModify) const {
  bool isPPC64 = TM.getSubtargetImpl()->isPPC64();

  // If the block has no terminators, it just falls into the block after it.
  MachineBasicBlock::iterator I = MBB.end();
  if (I == MBB.begin())
    return false;
  --I;
  while (I->isDebugValue()) {
    if (I == MBB.begin())
      return false;
    --I;
  }
  if (!isUnpredicatedTerminator(I))
    return false;

  // Get the last instruction in the block.
  MachineInstr *LastInst = I;

  // If there is only one terminator instruction, process it.
  if (I == MBB.begin() || !isUnpredicatedTerminator(--I)) {
    if (LastInst->getOpcode() == PPC::B) {
      if (!LastInst->getOperand(0).isMBB())
        return true;
      TBB = LastInst->getOperand(0).getMBB();
      return false;
    } else if (LastInst->getOpcode() == PPC::BCC) {
      if (!LastInst->getOperand(2).isMBB())
        return true;
      // Block ends with fall-through condbranch.
      TBB = LastInst->getOperand(2).getMBB();
      Cond.push_back(LastInst->getOperand(0));
      Cond.push_back(LastInst->getOperand(1));
      return false;
    } else if (LastInst->getOpcode() == PPC::BDNZ8 ||
               LastInst->getOpcode() == PPC::BDNZ) {
      if (!LastInst->getOperand(0).isMBB())
        return true;
      if (DisableCTRLoopAnal)
        return true;
      TBB = LastInst->getOperand(0).getMBB();
      Cond.push_back(MachineOperand::CreateImm(1));
      Cond.push_back(MachineOperand::CreateReg(isPPC64 ? PPC::CTR8 : PPC::CTR,
                                               true));
      return false;
    } else if (LastInst->getOpcode() == PPC::BDZ8 ||
               LastInst->getOpcode() == PPC::BDZ) {
      if (!LastInst->getOperand(0).isMBB())
        return true;
      if (DisableCTRLoopAnal)
        return true;
      TBB = LastInst->getOperand(0).getMBB();
      Cond.push_back(MachineOperand::CreateImm(0));
      Cond.push_back(MachineOperand::CreateReg(isPPC64 ? PPC::CTR8 : PPC::CTR,
                                               true));
      return false;
    }

    // Otherwise, don't know what this is.
    return true;
  }

  // Get the instruction before it if it's a terminator.
  MachineInstr *SecondLastInst = I;

  // If there are three terminators, we don't know what sort of block this is.
  if (SecondLastInst && I != MBB.begin() &&
      isUnpredicatedTerminator(--I))
    return true;

  // If the block ends with PPC::B and PPC:BCC, handle it.
  if (SecondLastInst->getOpcode() == PPC::BCC &&
      LastInst->getOpcode() == PPC::B) {
    if (!SecondLastInst->getOperand(2).isMBB() ||
        !LastInst->getOperand(0).isMBB())
      return true;
    TBB =  SecondLastInst->getOperand(2).getMBB();
    Cond.push_back(SecondLastInst->getOperand(0));
    Cond.push_back(SecondLastInst->getOperand(1));
    FBB = LastInst->getOperand(0).getMBB();
    return false;
  } else if ((SecondLastInst->getOpcode() == PPC::BDNZ8 ||
              SecondLastInst->getOpcode() == PPC::BDNZ) &&
      LastInst->getOpcode() == PPC::B) {
    if (!SecondLastInst->getOperand(0).isMBB() ||
        !LastInst->getOperand(0).isMBB())
      return true;
    if (DisableCTRLoopAnal)
      return true;
    TBB = SecondLastInst->getOperand(0).getMBB();
    Cond.push_back(MachineOperand::CreateImm(1));
    Cond.push_back(MachineOperand::CreateReg(isPPC64 ? PPC::CTR8 : PPC::CTR,
                                             true));
    FBB = LastInst->getOperand(0).getMBB();
    return false;
  } else if ((SecondLastInst->getOpcode() == PPC::BDZ8 ||
              SecondLastInst->getOpcode() == PPC::BDZ) &&
      LastInst->getOpcode() == PPC::B) {
    if (!SecondLastInst->getOperand(0).isMBB() ||
        !LastInst->getOperand(0).isMBB())
      return true;
    if (DisableCTRLoopAnal)
      return true;
    TBB = SecondLastInst->getOperand(0).getMBB();
    Cond.push_back(MachineOperand::CreateImm(0));
    Cond.push_back(MachineOperand::CreateReg(isPPC64 ? PPC::CTR8 : PPC::CTR,
                                             true));
    FBB = LastInst->getOperand(0).getMBB();
    return false;
  }

  // If the block ends with two PPC:Bs, handle it.  The second one is not
  // executed, so remove it.
  if (SecondLastInst->getOpcode() == PPC::B &&
      LastInst->getOpcode() == PPC::B) {
    if (!SecondLastInst->getOperand(0).isMBB())
      return true;
    TBB = SecondLastInst->getOperand(0).getMBB();
    I = LastInst;
    if (AllowModify)
      I->eraseFromParent();
    return false;
  }

  // Otherwise, can't handle this.
  return true;
}

unsigned PPCInstrInfo::RemoveBranch(MachineBasicBlock &MBB) const {
  MachineBasicBlock::iterator I = MBB.end();
  if (I == MBB.begin()) return 0;
  --I;
  while (I->isDebugValue()) {
    if (I == MBB.begin())
      return 0;
    --I;
  }
  if (I->getOpcode() != PPC::B && I->getOpcode() != PPC::BCC &&
      I->getOpcode() != PPC::BDNZ8 && I->getOpcode() != PPC::BDNZ &&
      I->getOpcode() != PPC::BDZ8  && I->getOpcode() != PPC::BDZ)
    return 0;

  // Remove the branch.
  I->eraseFromParent();

  I = MBB.end();

  if (I == MBB.begin()) return 1;
  --I;
  if (I->getOpcode() != PPC::BCC &&
      I->getOpcode() != PPC::BDNZ8 && I->getOpcode() != PPC::BDNZ &&
      I->getOpcode() != PPC::BDZ8  && I->getOpcode() != PPC::BDZ)
    return 1;

  // Remove the branch.
  I->eraseFromParent();
  return 2;
}

unsigned
PPCInstrInfo::InsertBranch(MachineBasicBlock &MBB, MachineBasicBlock *TBB,
                           MachineBasicBlock *FBB,
                           const SmallVectorImpl<MachineOperand> &Cond,
                           DebugLoc DL) const {
  // Shouldn't be a fall through.
  assert(TBB && "InsertBranch must not be told to insert a fallthrough");
  assert((Cond.size() == 2 || Cond.size() == 0) &&
         "PPC branch conditions have two components!");

  bool isPPC64 = TM.getSubtargetImpl()->isPPC64();

  // One-way branch.
  if (FBB == 0) {
    if (Cond.empty())   // Unconditional branch
      BuildMI(&MBB, DL, get(PPC::B)).addMBB(TBB);
    else if (Cond[1].getReg() == PPC::CTR || Cond[1].getReg() == PPC::CTR8)
      BuildMI(&MBB, DL, get(Cond[0].getImm() ?
                              (isPPC64 ? PPC::BDNZ8 : PPC::BDNZ) :
                              (isPPC64 ? PPC::BDZ8  : PPC::BDZ))).addMBB(TBB);
    else                // Conditional branch
      BuildMI(&MBB, DL, get(PPC::BCC))
        .addImm(Cond[0].getImm()).addReg(Cond[1].getReg()).addMBB(TBB);
    return 1;
  }

  // Two-way Conditional Branch.
  if (Cond[1].getReg() == PPC::CTR || Cond[1].getReg() == PPC::CTR8)
    BuildMI(&MBB, DL, get(Cond[0].getImm() ?
                            (isPPC64 ? PPC::BDNZ8 : PPC::BDNZ) :
                            (isPPC64 ? PPC::BDZ8  : PPC::BDZ))).addMBB(TBB);
  else
    BuildMI(&MBB, DL, get(PPC::BCC))
      .addImm(Cond[0].getImm()).addReg(Cond[1].getReg()).addMBB(TBB);
  BuildMI(&MBB, DL, get(PPC::B)).addMBB(FBB);
  return 2;
}

// Select analysis.
bool PPCInstrInfo::canInsertSelect(const MachineBasicBlock &MBB,
                const SmallVectorImpl<MachineOperand> &Cond,
                unsigned TrueReg, unsigned FalseReg,
                int &CondCycles, int &TrueCycles, int &FalseCycles) const {
  if (!TM.getSubtargetImpl()->hasISEL())
    return false;

  if (Cond.size() != 2)
    return false;

  // If this is really a bdnz-like condition, then it cannot be turned into a
  // select.
  if (Cond[1].getReg() == PPC::CTR || Cond[1].getReg() == PPC::CTR8)
    return false;

  // Check register classes.
  const MachineRegisterInfo &MRI = MBB.getParent()->getRegInfo();
  const TargetRegisterClass *RC =
    RI.getCommonSubClass(MRI.getRegClass(TrueReg), MRI.getRegClass(FalseReg));
  if (!RC)
    return false;

  // isel is for regular integer GPRs only.
  if (!PPC::GPRCRegClass.hasSubClassEq(RC) &&
      !PPC::G8RCRegClass.hasSubClassEq(RC))
    return false;

  // FIXME: These numbers are for the A2, how well they work for other cores is
  // an open question. On the A2, the isel instruction has a 2-cycle latency
  // but single-cycle throughput. These numbers are used in combination with
  // the MispredictPenalty setting from the active SchedMachineModel.
  CondCycles = 1;
  TrueCycles = 1;
  FalseCycles = 1;

  return true;
}

void PPCInstrInfo::insertSelect(MachineBasicBlock &MBB,
                                MachineBasicBlock::iterator MI, DebugLoc dl,
                                unsigned DestReg,
                                const SmallVectorImpl<MachineOperand> &Cond,
                                unsigned TrueReg, unsigned FalseReg) const {
  assert(Cond.size() == 2 &&
         "PPC branch conditions have two components!");

  assert(TM.getSubtargetImpl()->hasISEL() &&
         "Cannot insert select on target without ISEL support");

  // Get the register classes.
  MachineRegisterInfo &MRI = MBB.getParent()->getRegInfo();
  const TargetRegisterClass *RC =
    RI.getCommonSubClass(MRI.getRegClass(TrueReg), MRI.getRegClass(FalseReg));
  assert(RC && "TrueReg and FalseReg must have overlapping register classes");
  assert((PPC::GPRCRegClass.hasSubClassEq(RC) ||
          PPC::G8RCRegClass.hasSubClassEq(RC)) &&
         "isel is for regular integer GPRs only");

  unsigned OpCode =
    PPC::GPRCRegClass.hasSubClassEq(RC) ? PPC::ISEL : PPC::ISEL8;
  unsigned SelectPred = Cond[0].getImm();

  unsigned SubIdx;
  bool SwapOps;
  switch (SelectPred) {
  default: llvm_unreachable("invalid predicate for isel");
  case PPC::PRED_EQ: SubIdx = PPC::sub_eq; SwapOps = false; break;
  case PPC::PRED_NE: SubIdx = PPC::sub_eq; SwapOps = true; break;
  case PPC::PRED_LT: SubIdx = PPC::sub_lt; SwapOps = false; break;
  case PPC::PRED_GE: SubIdx = PPC::sub_lt; SwapOps = true; break;
  case PPC::PRED_GT: SubIdx = PPC::sub_gt; SwapOps = false; break;
  case PPC::PRED_LE: SubIdx = PPC::sub_gt; SwapOps = true; break;
  case PPC::PRED_UN: SubIdx = PPC::sub_un; SwapOps = false; break;
  case PPC::PRED_NU: SubIdx = PPC::sub_un; SwapOps = true; break;
  }

  unsigned FirstReg =  SwapOps ? FalseReg : TrueReg,
           SecondReg = SwapOps ? TrueReg  : FalseReg;

  // The first input register of isel cannot be r0. If it is a member
  // of a register class that can be r0, then copy it first (the
  // register allocator should eliminate the copy).
  if (MRI.getRegClass(FirstReg)->contains(PPC::R0) ||
      MRI.getRegClass(FirstReg)->contains(PPC::X0)) {
    const TargetRegisterClass *FirstRC =
      MRI.getRegClass(FirstReg)->contains(PPC::X0) ?
        &PPC::G8RC_NOX0RegClass : &PPC::GPRC_NOR0RegClass;
    unsigned OldFirstReg = FirstReg;
    FirstReg = MRI.createVirtualRegister(FirstRC);
    BuildMI(MBB, MI, dl, get(TargetOpcode::COPY), FirstReg)
      .addReg(OldFirstReg);
  }

  BuildMI(MBB, MI, dl, get(OpCode), DestReg)
    .addReg(FirstReg).addReg(SecondReg)
    .addReg(Cond[1].getReg(), 0, SubIdx);
}

void PPCInstrInfo::copyPhysReg(MachineBasicBlock &MBB,
                               MachineBasicBlock::iterator I, DebugLoc DL,
                               unsigned DestReg, unsigned SrcReg,
                               bool KillSrc) const {
  unsigned Opc;
  if (PPC::GPRCRegClass.contains(DestReg, SrcReg))
    Opc = PPC::OR;
  else if (PPC::G8RCRegClass.contains(DestReg, SrcReg))
    Opc = PPC::OR8;
  else if (PPC::F4RCRegClass.contains(DestReg, SrcReg))
    Opc = PPC::FMR;
  else if (PPC::CRRCRegClass.contains(DestReg, SrcReg))
    Opc = PPC::MCRF;
  else if (PPC::VRRCRegClass.contains(DestReg, SrcReg))
    Opc = PPC::VOR;
  else if (PPC::CRBITRCRegClass.contains(DestReg, SrcReg))
    Opc = PPC::CROR;
  else
    llvm_unreachable("Impossible reg-to-reg copy");

  const MCInstrDesc &MCID = get(Opc);
  if (MCID.getNumOperands() == 3)
    BuildMI(MBB, I, DL, MCID, DestReg)
      .addReg(SrcReg).addReg(SrcReg, getKillRegState(KillSrc));
  else
    BuildMI(MBB, I, DL, MCID, DestReg).addReg(SrcReg, getKillRegState(KillSrc));
}

// This function returns true if a CR spill is necessary and false otherwise.
bool
PPCInstrInfo::StoreRegToStackSlot(MachineFunction &MF,
                                  unsigned SrcReg, bool isKill,
                                  int FrameIdx,
                                  const TargetRegisterClass *RC,
                                  SmallVectorImpl<MachineInstr*> &NewMIs,
                                  bool &NonRI, bool &SpillsVRS) const{
  // Note: If additional store instructions are added here,
  // update isStoreToStackSlot.

  DebugLoc DL;
  if (PPC::GPRCRegClass.hasSubClassEq(RC)) {
    NewMIs.push_back(addFrameReference(BuildMI(MF, DL, get(PPC::STW))
                                       .addReg(SrcReg,
                                               getKillRegState(isKill)),
                                       FrameIdx));
  } else if (PPC::G8RCRegClass.hasSubClassEq(RC)) {
    NewMIs.push_back(addFrameReference(BuildMI(MF, DL, get(PPC::STD))
                                       .addReg(SrcReg,
                                               getKillRegState(isKill)),
                                       FrameIdx));
  } else if (PPC::F8RCRegClass.hasSubClassEq(RC)) {
    NewMIs.push_back(addFrameReference(BuildMI(MF, DL, get(PPC::STFD))
                                       .addReg(SrcReg,
                                               getKillRegState(isKill)),
                                       FrameIdx));
  } else if (PPC::F4RCRegClass.hasSubClassEq(RC)) {
    NewMIs.push_back(addFrameReference(BuildMI(MF, DL, get(PPC::STFS))
                                       .addReg(SrcReg,
                                               getKillRegState(isKill)),
                                       FrameIdx));
  } else if (PPC::CRRCRegClass.hasSubClassEq(RC)) {
    NewMIs.push_back(addFrameReference(BuildMI(MF, DL, get(PPC::SPILL_CR))
                                       .addReg(SrcReg,
                                               getKillRegState(isKill)),
                                       FrameIdx));
    return true;
  } else if (PPC::CRBITRCRegClass.hasSubClassEq(RC)) {
    // FIXME: We use CRi here because there is no mtcrf on a bit. Since the
    // backend currently only uses CR1EQ as an individual bit, this should
    // not cause any bug. If we need other uses of CR bits, the following
    // code may be invalid.
    unsigned Reg = 0;
    if (SrcReg == PPC::CR0LT || SrcReg == PPC::CR0GT ||
        SrcReg == PPC::CR0EQ || SrcReg == PPC::CR0UN)
      Reg = PPC::CR0;
    else if (SrcReg == PPC::CR1LT || SrcReg == PPC::CR1GT ||
             SrcReg == PPC::CR1EQ || SrcReg == PPC::CR1UN)
      Reg = PPC::CR1;
    else if (SrcReg == PPC::CR2LT || SrcReg == PPC::CR2GT ||
             SrcReg == PPC::CR2EQ || SrcReg == PPC::CR2UN)
      Reg = PPC::CR2;
    else if (SrcReg == PPC::CR3LT || SrcReg == PPC::CR3GT ||
             SrcReg == PPC::CR3EQ || SrcReg == PPC::CR3UN)
      Reg = PPC::CR3;
    else if (SrcReg == PPC::CR4LT || SrcReg == PPC::CR4GT ||
             SrcReg == PPC::CR4EQ || SrcReg == PPC::CR4UN)
      Reg = PPC::CR4;
    else if (SrcReg == PPC::CR5LT || SrcReg == PPC::CR5GT ||
             SrcReg == PPC::CR5EQ || SrcReg == PPC::CR5UN)
      Reg = PPC::CR5;
    else if (SrcReg == PPC::CR6LT || SrcReg == PPC::CR6GT ||
             SrcReg == PPC::CR6EQ || SrcReg == PPC::CR6UN)
      Reg = PPC::CR6;
    else if (SrcReg == PPC::CR7LT || SrcReg == PPC::CR7GT ||
             SrcReg == PPC::CR7EQ || SrcReg == PPC::CR7UN)
      Reg = PPC::CR7;

    return StoreRegToStackSlot(MF, Reg, isKill, FrameIdx,
                               &PPC::CRRCRegClass, NewMIs, NonRI, SpillsVRS);

  } else if (PPC::VRRCRegClass.hasSubClassEq(RC)) {
    NewMIs.push_back(addFrameReference(BuildMI(MF, DL, get(PPC::STVX))
                                       .addReg(SrcReg,
                                               getKillRegState(isKill)),
                                       FrameIdx));
    NonRI = true;
  } else if (PPC::VRSAVERCRegClass.hasSubClassEq(RC)) {
    assert(TM.getSubtargetImpl()->isDarwin() &&
           "VRSAVE only needs spill/restore on Darwin");
    NewMIs.push_back(addFrameReference(BuildMI(MF, DL, get(PPC::SPILL_VRSAVE))
                                       .addReg(SrcReg,
                                               getKillRegState(isKill)),
                                       FrameIdx));
    SpillsVRS = true;
  } else {
    llvm_unreachable("Unknown regclass!");
  }

  return false;
}

void
PPCInstrInfo::storeRegToStackSlot(MachineBasicBlock &MBB,
                                  MachineBasicBlock::iterator MI,
                                  unsigned SrcReg, bool isKill, int FrameIdx,
                                  const TargetRegisterClass *RC,
                                  const TargetRegisterInfo *TRI) const {
  MachineFunction &MF = *MBB.getParent();
  SmallVector<MachineInstr*, 4> NewMIs;

  PPCFunctionInfo *FuncInfo = MF.getInfo<PPCFunctionInfo>();
  FuncInfo->setHasSpills();

  bool NonRI = false, SpillsVRS = false;
  if (StoreRegToStackSlot(MF, SrcReg, isKill, FrameIdx, RC, NewMIs,
                          NonRI, SpillsVRS))
    FuncInfo->setSpillsCR();

  if (SpillsVRS)
    FuncInfo->setSpillsVRSAVE();

  if (NonRI)
    FuncInfo->setHasNonRISpills();

  for (unsigned i = 0, e = NewMIs.size(); i != e; ++i)
    MBB.insert(MI, NewMIs[i]);

  const MachineFrameInfo &MFI = *MF.getFrameInfo();
  MachineMemOperand *MMO =
    MF.getMachineMemOperand(MachinePointerInfo::getFixedStack(FrameIdx),
                            MachineMemOperand::MOStore,
                            MFI.getObjectSize(FrameIdx),
                            MFI.getObjectAlignment(FrameIdx));
  NewMIs.back()->addMemOperand(MF, MMO);
}

bool
PPCInstrInfo::LoadRegFromStackSlot(MachineFunction &MF, DebugLoc DL,
                                   unsigned DestReg, int FrameIdx,
                                   const TargetRegisterClass *RC,
                                   SmallVectorImpl<MachineInstr*> &NewMIs,
                                   bool &NonRI, bool &SpillsVRS) const{
  // Note: If additional load instructions are added here,
  // update isLoadFromStackSlot.

  if (PPC::GPRCRegClass.hasSubClassEq(RC)) {
    NewMIs.push_back(addFrameReference(BuildMI(MF, DL, get(PPC::LWZ),
                                               DestReg), FrameIdx));
  } else if (PPC::G8RCRegClass.hasSubClassEq(RC)) {
    NewMIs.push_back(addFrameReference(BuildMI(MF, DL, get(PPC::LD), DestReg),
                                       FrameIdx));
  } else if (PPC::F8RCRegClass.hasSubClassEq(RC)) {
    NewMIs.push_back(addFrameReference(BuildMI(MF, DL, get(PPC::LFD), DestReg),
                                       FrameIdx));
  } else if (PPC::F4RCRegClass.hasSubClassEq(RC)) {
    NewMIs.push_back(addFrameReference(BuildMI(MF, DL, get(PPC::LFS), DestReg),
                                       FrameIdx));
  } else if (PPC::CRRCRegClass.hasSubClassEq(RC)) {
    NewMIs.push_back(addFrameReference(BuildMI(MF, DL,
                                               get(PPC::RESTORE_CR), DestReg),
                                       FrameIdx));
    return true;
  } else if (PPC::CRBITRCRegClass.hasSubClassEq(RC)) {

    unsigned Reg = 0;
    if (DestReg == PPC::CR0LT || DestReg == PPC::CR0GT ||
        DestReg == PPC::CR0EQ || DestReg == PPC::CR0UN)
      Reg = PPC::CR0;
    else if (DestReg == PPC::CR1LT || DestReg == PPC::CR1GT ||
             DestReg == PPC::CR1EQ || DestReg == PPC::CR1UN)
      Reg = PPC::CR1;
    else if (DestReg == PPC::CR2LT || DestReg == PPC::CR2GT ||
             DestReg == PPC::CR2EQ || DestReg == PPC::CR2UN)
      Reg = PPC::CR2;
    else if (DestReg == PPC::CR3LT || DestReg == PPC::CR3GT ||
             DestReg == PPC::CR3EQ || DestReg == PPC::CR3UN)
      Reg = PPC::CR3;
    else if (DestReg == PPC::CR4LT || DestReg == PPC::CR4GT ||
             DestReg == PPC::CR4EQ || DestReg == PPC::CR4UN)
      Reg = PPC::CR4;
    else if (DestReg == PPC::CR5LT || DestReg == PPC::CR5GT ||
             DestReg == PPC::CR5EQ || DestReg == PPC::CR5UN)
      Reg = PPC::CR5;
    else if (DestReg == PPC::CR6LT || DestReg == PPC::CR6GT ||
             DestReg == PPC::CR6EQ || DestReg == PPC::CR6UN)
      Reg = PPC::CR6;
    else if (DestReg == PPC::CR7LT || DestReg == PPC::CR7GT ||
             DestReg == PPC::CR7EQ || DestReg == PPC::CR7UN)
      Reg = PPC::CR7;

    return LoadRegFromStackSlot(MF, DL, Reg, FrameIdx,
                                &PPC::CRRCRegClass, NewMIs, NonRI, SpillsVRS);

  } else if (PPC::VRRCRegClass.hasSubClassEq(RC)) {
    NewMIs.push_back(addFrameReference(BuildMI(MF, DL, get(PPC::LVX), DestReg),
                                       FrameIdx));
    NonRI = true;
  } else if (PPC::VRSAVERCRegClass.hasSubClassEq(RC)) {
    assert(TM.getSubtargetImpl()->isDarwin() &&
           "VRSAVE only needs spill/restore on Darwin");
    NewMIs.push_back(addFrameReference(BuildMI(MF, DL,
                                               get(PPC::RESTORE_VRSAVE),
                                               DestReg),
                                       FrameIdx));
    SpillsVRS = true;
  } else {
    llvm_unreachable("Unknown regclass!");
  }

  return false;
}

void
PPCInstrInfo::loadRegFromStackSlot(MachineBasicBlock &MBB,
                                   MachineBasicBlock::iterator MI,
                                   unsigned DestReg, int FrameIdx,
                                   const TargetRegisterClass *RC,
                                   const TargetRegisterInfo *TRI) const {
  MachineFunction &MF = *MBB.getParent();
  SmallVector<MachineInstr*, 4> NewMIs;
  DebugLoc DL;
  if (MI != MBB.end()) DL = MI->getDebugLoc();

  PPCFunctionInfo *FuncInfo = MF.getInfo<PPCFunctionInfo>();
  FuncInfo->setHasSpills();

  bool NonRI = false, SpillsVRS = false;
  if (LoadRegFromStackSlot(MF, DL, DestReg, FrameIdx, RC, NewMIs,
                           NonRI, SpillsVRS))
    FuncInfo->setSpillsCR();

  if (SpillsVRS)
    FuncInfo->setSpillsVRSAVE();

  if (NonRI)
    FuncInfo->setHasNonRISpills();

  for (unsigned i = 0, e = NewMIs.size(); i != e; ++i)
    MBB.insert(MI, NewMIs[i]);

  const MachineFrameInfo &MFI = *MF.getFrameInfo();
  MachineMemOperand *MMO =
    MF.getMachineMemOperand(MachinePointerInfo::getFixedStack(FrameIdx),
                            MachineMemOperand::MOLoad,
                            MFI.getObjectSize(FrameIdx),
                            MFI.getObjectAlignment(FrameIdx));
  NewMIs.back()->addMemOperand(MF, MMO);
}

MachineInstr*
PPCInstrInfo::emitFrameIndexDebugValue(MachineFunction &MF,
                                       int FrameIx, uint64_t Offset,
                                       const MDNode *MDPtr,
                                       DebugLoc DL) const {
  MachineInstrBuilder MIB = BuildMI(MF, DL, get(PPC::DBG_VALUE));
  addFrameReference(MIB, FrameIx, 0, false).addImm(Offset).addMetadata(MDPtr);
  return &*MIB;
}

bool PPCInstrInfo::
ReverseBranchCondition(SmallVectorImpl<MachineOperand> &Cond) const {
  assert(Cond.size() == 2 && "Invalid PPC branch opcode!");
  if (Cond[1].getReg() == PPC::CTR8 || Cond[1].getReg() == PPC::CTR)
    Cond[0].setImm(Cond[0].getImm() == 0 ? 1 : 0);
  else
    // Leave the CR# the same, but invert the condition.
    Cond[0].setImm(PPC::InvertPredicate((PPC::Predicate)Cond[0].getImm()));
  return false;
}

bool PPCInstrInfo::FoldImmediate(MachineInstr *UseMI, MachineInstr *DefMI,
                             unsigned Reg, MachineRegisterInfo *MRI) const {
  // For some instructions, it is legal to fold ZERO into the RA register field.
  // A zero immediate should always be loaded with a single li.
  unsigned DefOpc = DefMI->getOpcode();
  if (DefOpc != PPC::LI && DefOpc != PPC::LI8)
    return false;
  if (!DefMI->getOperand(1).isImm())
    return false;
  if (DefMI->getOperand(1).getImm() != 0)
    return false;

  // Note that we cannot here invert the arguments of an isel in order to fold
  // a ZERO into what is presented as the second argument. All we have here
  // is the condition bit, and that might come from a CR-logical bit operation.

  const MCInstrDesc &UseMCID = UseMI->getDesc();

  // Only fold into real machine instructions.
  if (UseMCID.isPseudo())
    return false;

  unsigned UseIdx;
  for (UseIdx = 0; UseIdx < UseMI->getNumOperands(); ++UseIdx)
    if (UseMI->getOperand(UseIdx).isReg() &&
        UseMI->getOperand(UseIdx).getReg() == Reg)
      break;

  assert(UseIdx < UseMI->getNumOperands() && "Cannot find Reg in UseMI");
  assert(UseIdx < UseMCID.getNumOperands() && "No operand description for Reg");

  const MCOperandInfo *UseInfo = &UseMCID.OpInfo[UseIdx];

  // We can fold the zero if this register requires a GPRC_NOR0/G8RC_NOX0
  // register (which might also be specified as a pointer class kind).
  if (UseInfo->isLookupPtrRegClass()) {
    if (UseInfo->RegClass /* Kind */ != 1)
      return false;
  } else {
    if (UseInfo->RegClass != PPC::GPRC_NOR0RegClassID &&
        UseInfo->RegClass != PPC::G8RC_NOX0RegClassID)
      return false;
  }

  // Make sure this is not tied to an output register (or otherwise
  // constrained). This is true for ST?UX registers, for example, which
  // are tied to their output registers.
  if (UseInfo->Constraints != 0)
    return false;

  unsigned ZeroReg;
  if (UseInfo->isLookupPtrRegClass()) {
    bool isPPC64 = TM.getSubtargetImpl()->isPPC64();
    ZeroReg = isPPC64 ? PPC::ZERO8 : PPC::ZERO;
  } else {
    ZeroReg = UseInfo->RegClass == PPC::G8RC_NOX0RegClassID ?
              PPC::ZERO8 : PPC::ZERO;
  }

  bool DeleteDef = MRI->hasOneNonDBGUse(Reg);
  UseMI->getOperand(UseIdx).setReg(ZeroReg);

  if (DeleteDef)
    DefMI->eraseFromParent();

  return true;
}

bool PPCInstrInfo::isPredicated(const MachineInstr *MI) const {
  unsigned OpC = MI->getOpcode();
  switch (OpC) {
  default:
    return false;
  case PPC::BCC:
  case PPC::BCLR:
  case PPC::BDZLR:
  case PPC::BDZLR8:
  case PPC::BDNZLR:
  case PPC::BDNZLR8:
    return true;
  }
}

bool PPCInstrInfo::isUnpredicatedTerminator(const MachineInstr *MI) const {
  if (!MI->isTerminator())
    return false;

  // Conditional branch is a special case.
  if (MI->isBranch() && !MI->isBarrier())
    return true;

  return !isPredicated(MI);
}

bool PPCInstrInfo::PredicateInstruction(
                     MachineInstr *MI,
                     const SmallVectorImpl<MachineOperand> &Pred) const {
  unsigned OpC = MI->getOpcode();
  if (OpC == PPC::BLR) {
    if (Pred[1].getReg() == PPC::CTR8 || Pred[1].getReg() == PPC::CTR) {
      bool isPPC64 = TM.getSubtargetImpl()->isPPC64();
      MI->setDesc(get(Pred[0].getImm() ?
                      (isPPC64 ? PPC::BDNZLR8 : PPC::BDNZLR) :
                      (isPPC64 ? PPC::BDZLR8  : PPC::BDZLR)));
    } else {
      MI->setDesc(get(PPC::BCLR));
      MachineInstrBuilder(*MI->getParent()->getParent(), MI)
        .addImm(Pred[0].getImm())
        .addReg(Pred[1].getReg());
    }

    return true;
  } else if (OpC == PPC::B) {
    if (Pred[1].getReg() == PPC::CTR8 || Pred[1].getReg() == PPC::CTR) {
      bool isPPC64 = TM.getSubtargetImpl()->isPPC64();
      MI->setDesc(get(Pred[0].getImm() ?
                      (isPPC64 ? PPC::BDNZ8 : PPC::BDNZ) :
                      (isPPC64 ? PPC::BDZ8  : PPC::BDZ)));
    } else {
      MachineBasicBlock *MBB = MI->getOperand(0).getMBB();
      MI->RemoveOperand(0);

      MI->setDesc(get(PPC::BCC));
      MachineInstrBuilder(*MI->getParent()->getParent(), MI)
        .addImm(Pred[0].getImm())
        .addReg(Pred[1].getReg())
        .addMBB(MBB);
    }

    return true;
  }

  return false;
}

bool PPCInstrInfo::SubsumesPredicate(
                     const SmallVectorImpl<MachineOperand> &Pred1,
                     const SmallVectorImpl<MachineOperand> &Pred2) const {
  assert(Pred1.size() == 2 && "Invalid PPC first predicate");
  assert(Pred2.size() == 2 && "Invalid PPC second predicate");

  if (Pred1[1].getReg() == PPC::CTR8 || Pred1[1].getReg() == PPC::CTR)
    return false;
  if (Pred2[1].getReg() == PPC::CTR8 || Pred2[1].getReg() == PPC::CTR)
    return false;

  PPC::Predicate P1 = (PPC::Predicate) Pred1[0].getImm();
  PPC::Predicate P2 = (PPC::Predicate) Pred2[0].getImm();

  if (P1 == P2)
    return true;

  // Does P1 subsume P2, e.g. GE subsumes GT.
  if (P1 == PPC::PRED_LE &&
      (P2 == PPC::PRED_LT || P2 == PPC::PRED_EQ))
    return true;
  if (P1 == PPC::PRED_GE &&
      (P2 == PPC::PRED_GT || P2 == PPC::PRED_EQ))
    return true;

  return false;
}

bool PPCInstrInfo::DefinesPredicate(MachineInstr *MI,
                                    std::vector<MachineOperand> &Pred) const {
  // Note: At the present time, the contents of Pred from this function is
  // unused by IfConversion. This implementation follows ARM by pushing the
  // CR-defining operand. Because the 'DZ' and 'DNZ' count as types of
  // predicate, instructions defining CTR or CTR8 are also included as
  // predicate-defining instructions.

  const TargetRegisterClass *RCs[] =
    { &PPC::CRRCRegClass, &PPC::CRBITRCRegClass,
      &PPC::CTRRCRegClass, &PPC::CTRRC8RegClass };

  bool Found = false;
  for (unsigned i = 0, e = MI->getNumOperands(); i != e; ++i) {
    const MachineOperand &MO = MI->getOperand(i);
    for (int c = 0; c < 2 && !Found; ++c) {
      const TargetRegisterClass *RC = RCs[c];
      for (TargetRegisterClass::iterator I = RC->begin(),
           IE = RC->end(); I != IE; ++I) {
        if ((MO.isRegMask() && MO.clobbersPhysReg(*I)) ||
            (MO.isReg() && MO.isDef() && MO.getReg() == *I)) {
          Pred.push_back(MO);
          Found = true;
        }
      }
    }
  }

  return Found;
}

bool PPCInstrInfo::isPredicable(MachineInstr *MI) const {
  unsigned OpC = MI->getOpcode();
  switch (OpC) {
  default:
    return false;
  case PPC::B:
  case PPC::BLR:
    return true;
  }
}

/// GetInstSize - Return the number of bytes of code the specified
/// instruction may be.  This returns the maximum number of bytes.
///
unsigned PPCInstrInfo::GetInstSizeInBytes(const MachineInstr *MI) const {
  switch (MI->getOpcode()) {
  case PPC::INLINEASM: {       // Inline Asm: Variable size.
    const MachineFunction *MF = MI->getParent()->getParent();
    const char *AsmStr = MI->getOperand(0).getSymbolName();
    return getInlineAsmLength(AsmStr, *MF->getTarget().getMCAsmInfo());
  }
  case PPC::PROLOG_LABEL:
  case PPC::EH_LABEL:
  case PPC::GC_LABEL:
  case PPC::DBG_VALUE:
    return 0;
  case PPC::BL8_NOP:
  case PPC::BLA8_NOP:
    return 8;
  default:
    return 4; // PowerPC instructions are all 4 bytes
  }
}

#undef DEBUG_TYPE
#define DEBUG_TYPE "ppc-early-ret"
STATISTIC(NumBCLR, "Number of early conditional returns");
STATISTIC(NumBLR,  "Number of early returns");

namespace llvm {
  void initializePPCEarlyReturnPass(PassRegistry&);
}

namespace {
  // PPCEarlyReturn pass - For simple functions without epilogue code, move
  // returns up, and create conditional returns, to avoid unnecessary
  // branch-to-blr sequences.
  struct PPCEarlyReturn : public MachineFunctionPass {
    static char ID;
    PPCEarlyReturn() : MachineFunctionPass(ID) {
      initializePPCEarlyReturnPass(*PassRegistry::getPassRegistry());
    }

    const PPCTargetMachine *TM;
    const PPCInstrInfo *TII;

protected:
    bool processBlock(MachineBasicBlock &ReturnMBB) {
      bool Changed = false;

      MachineBasicBlock::iterator I = ReturnMBB.begin();
      I = ReturnMBB.SkipPHIsAndLabels(I);

      // The block must be essentially empty except for the blr.
      if (I == ReturnMBB.end() || I->getOpcode() != PPC::BLR ||
          I != ReturnMBB.getLastNonDebugInstr())
        return Changed;

      SmallVector<MachineBasicBlock*, 8> PredToRemove;
      for (MachineBasicBlock::pred_iterator PI = ReturnMBB.pred_begin(),
           PIE = ReturnMBB.pred_end(); PI != PIE; ++PI) {
        bool OtherReference = false, BlockChanged = false;
        for (MachineBasicBlock::iterator J = (*PI)->getLastNonDebugInstr();;) {
          if (J->getOpcode() == PPC::B) {
            if (J->getOperand(0).getMBB() == &ReturnMBB) {
              // This is an unconditional branch to the return. Replace the
	      // branch with a blr.
              BuildMI(**PI, J, J->getDebugLoc(), TII->get(PPC::BLR));
              MachineBasicBlock::iterator K = J--;
              K->eraseFromParent();
              BlockChanged = true;
              ++NumBLR;
              continue;
            }
          } else if (J->getOpcode() == PPC::BCC) {
            if (J->getOperand(2).getMBB() == &ReturnMBB) {
              // This is a conditional branch to the return. Replace the branch
              // with a bclr.
              BuildMI(**PI, J, J->getDebugLoc(), TII->get(PPC::BCLR))
                .addImm(J->getOperand(0).getImm())
                .addReg(J->getOperand(1).getReg());
              MachineBasicBlock::iterator K = J--;
              K->eraseFromParent();
              BlockChanged = true;
              ++NumBCLR;
              continue;
            }
          } else if (J->isBranch()) {
            if (J->isIndirectBranch()) {
              if (ReturnMBB.hasAddressTaken())
                OtherReference = true;
            } else
              for (unsigned i = 0; i < J->getNumOperands(); ++i)
                if (J->getOperand(i).isMBB() &&
                    J->getOperand(i).getMBB() == &ReturnMBB)
                  OtherReference = true;
          } else if (!J->isTerminator() && !J->isDebugValue())
            break;

          if (J == (*PI)->begin())
            break;

          --J;
        }

        if ((*PI)->canFallThrough() && (*PI)->isLayoutSuccessor(&ReturnMBB))
          OtherReference = true;

	// Predecessors are stored in a vector and can't be removed here.
        if (!OtherReference && BlockChanged) {
          PredToRemove.push_back(*PI);
        }

        if (BlockChanged)
          Changed = true;
      }

      for (unsigned i = 0, ie = PredToRemove.size(); i != ie; ++i)
        PredToRemove[i]->removeSuccessor(&ReturnMBB);

      if (Changed && !ReturnMBB.hasAddressTaken()) {
        // We now might be able to merge this blr-only block into its
        // by-layout predecessor.
        if (ReturnMBB.pred_size() == 1 &&
            (*ReturnMBB.pred_begin())->isLayoutSuccessor(&ReturnMBB)) {
          // Move the blr into the preceding block.
          MachineBasicBlock &PrevMBB = **ReturnMBB.pred_begin();
          PrevMBB.splice(PrevMBB.end(), &ReturnMBB, I);
          PrevMBB.removeSuccessor(&ReturnMBB);
        }

        if (ReturnMBB.pred_empty())
          ReturnMBB.eraseFromParent();
      }

      return Changed;
    }

public:
    virtual bool runOnMachineFunction(MachineFunction &MF) {
      TM = static_cast<const PPCTargetMachine *>(&MF.getTarget());
      TII = TM->getInstrInfo();

      bool Changed = false;

      // If the function does not have at least two blocks, then there is
      // nothing to do.
      if (MF.size() < 2)
        return Changed;

      for (MachineFunction::iterator I = MF.begin(); I != MF.end();) {
        MachineBasicBlock &B = *I++; 
        if (processBlock(B))
          Changed = true;
      }

      return Changed;
    }

    virtual void getAnalysisUsage(AnalysisUsage &AU) const {
      MachineFunctionPass::getAnalysisUsage(AU);
    }
  };
}

INITIALIZE_PASS(PPCEarlyReturn, DEBUG_TYPE,
                "PowerPC Early-Return Creation", false, false)

char PPCEarlyReturn::ID = 0;
FunctionPass*
llvm::createPPCEarlyReturnPass() { return new PPCEarlyReturn(); }

