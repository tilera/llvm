//===-- TileFrameLowering.cpp - Tile Frame Information --------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the Tile implementation of TargetFrameLowering class.
//
//===----------------------------------------------------------------------===//

#include "TileFrameLowering.h"
#include "TileInstrInfo.h"
#include "TileMachineFunction.h"
#include "MCTargetDesc/TileBaseInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineModuleInfo.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/Target/TargetOptions.h"
#include "llvm/Support/CommandLine.h"

using namespace llvm;

// Return true if the specified function should have a dedicated frame
// pointer register.  This is true if the function has variable sized
// allocas or if frame pointer elimination is disabled.
bool TileFrameLowering::hasFP(const MachineFunction &MF) const {
  const MachineFrameInfo *MFI = MF.getFrameInfo();
  return (MF.getTarget().Options.DisableFramePointerElim(MF) &&
          MFI->hasCalls()) ||
         MFI->hasVarSizedObjects() || MFI->isFrameAddressTaken();
}

bool TileFrameLowering::hasReservedCallFrame(const MachineFunction &MF) const {
  return !MF.getFrameInfo()->hasVarSizedObjects();
}

static void
addImmR(unsigned Dreg, unsigned Treg, int64_t Imm, const TileInstrInfo &TII,
        MachineBasicBlock &MBB, MachineBasicBlock::iterator II, DebugLoc DL) {
  if (isInt<8>(Imm))
    BuildMI(MBB, II, DL, TII.get(Tile::ADDI), Dreg).addReg(Dreg).addImm(Imm);
  else if (isInt<16>(Imm))
    BuildMI(MBB, II, DL, TII.get(Tile::ADDLI), Dreg).addReg(Dreg).addImm(Imm);
  else if (isInt<32>(Imm)) {
    BuildMI(MBB, II, DL, TII.get(Tile::MOVELI), Treg)
        .addImm((((uint64_t) Imm) >> 16) & 0xFFFF);
    BuildMI(MBB, II, DL, TII.get(Tile::SHL16INSLI), Treg).addReg(Treg)
        .addImm(Imm & ((1 << 16) - 1));
    BuildMI(MBB, II, DL, TII.get(Tile::ADD), Dreg).addReg(Dreg).addReg(Treg);
  } else {
    assert(isInt<64>(Imm) && "do not support Imm > 32bit yet");
    BuildMI(MBB, II, DL, TII.get(Tile::MOVELI), Treg)
        .addImm((((uint64_t) Imm) >> 32) & 0xFFFF);
    BuildMI(MBB, II, DL, TII.get(Tile::SHL16INSLI), Treg).addReg(Treg)
        .addImm((((uint64_t) Imm) >> 16) & 0xFFFF);
    BuildMI(MBB, II, DL, TII.get(Tile::SHL16INSLI), Treg).addReg(Treg)
        .addImm(Imm & ((1 << 16) - 1));
    BuildMI(MBB, II, DL, TII.get(Tile::ADD), Dreg).addReg(Dreg).addReg(Treg);
  }
}

// The stack frame looks like this: (copy from tile gcc)
//         +-------------+
//         |    ...      |
//         |  incoming   |
//         | stack args  |
//   AP -> +-------------+
//         | caller's HFP|
//         +-------------+
//         | lr save     |
//  HFP -> +-------------+
//         | special reg |
//         |-------------|
//         |  var args   |
//         |  reg save   |
//         +-------------+
//         |    ...      |
//         | saved regs  |
//   FP -> +-------------+
//         |    ...      |
//         |   vars      |
//         +-------------+
//         |    ...      |
//         |  outgoing   |
//         |  stack args |
//         +-------------+
//         | HFP         | ptr_size bytes (only here if nonleaf / alloca)
//         +-------------+
//         | callee lr   | ptr_size bytes (only here if nonleaf / alloca)
//         | save        |
//   SP -> +-------------+
//
//  HFP == incoming SP.
//
//  For functions with a frame larger than 32767 bytes, or which use
//  alloca (), r52 is used as a frame pointer.  Otherwise there is no
//  frame pointer.
//
//  FP is saved at SP+ptr_size before calling a subroutine so the callee
//  can chain.
void TileFrameLowering::emitPrologue(MachineFunction &MF) const {
  MachineBasicBlock &MBB = MF.front();
  MachineFrameInfo *MFI = MF.getFrameInfo();
  const TileInstrInfo &TII =
      *static_cast<const TileInstrInfo *>(MF.getTarget().getInstrInfo());
  MachineBasicBlock::iterator MBBI = MBB.begin();
  DebugLoc dl = MBBI != MBB.end() ? MBBI->getDebugLoc() : DebugLoc();
  unsigned SP = Tile::SP;
  unsigned ZERO = Tile::ZERO;
  unsigned TempReg0 = Tile::R10;
  unsigned TempReg1 = Tile::R11;

  // First, compute final stack size.
  unsigned RegSize = 8;
  unsigned StackAlign = getStackAlignment();
  uint64_t StackSize = (MFI->hasCalls() ? 2 * RegSize : 0) +
                       RoundUpToAlignment(MFI->getStackSize(), StackAlign);

  // Update stack size.
  MFI->setStackSize(StackSize);

  // No need to allocate space on the stack.
  if (StackSize == 0 && !MFI->adjustsStack())
    return;

  MachineModuleInfo &MMI = MF.getMMI();
  std::vector<MachineMove> &Moves = MMI.getFrameMoves();
  MachineLocation DstML, SrcML;

  if (MFI->hasCalls()) {
    // Copy incoming sp into TempReg1.
    BuildMI(MBB, MBBI, dl, TII.get(Tile::ADD), TempReg1).addReg(SP)
        .addReg(ZERO);

    // Save lr to caller's stack reserve slot 0.
    BuildMI(MBB, MBBI, dl, TII.get(Tile::ST)).addReg(SP).addReg(Tile::LR);
    // Emit ".cfi_offset" for lr.
    MCSymbol *CSLabel = MMI.getContext().CreateTempSymbol();
    BuildMI(MBB, MBBI, dl, TII.get(TargetOpcode::PROLOG_LABEL)).addSym(CSLabel);
    DstML = MachineLocation(MachineLocation::VirtualFP, 0);
    SrcML = MachineLocation(Tile::LR);
    Moves.push_back(MachineMove(CSLabel, DstML, SrcML));
  }

  // Adjust stack.
  addImmR(SP, TempReg0, -StackSize, TII, MBB, MBBI, dl);

  if (MFI->hasCalls()) {
    BuildMI(MBB, MBBI, dl, TII.get(Tile::ADDI), TempReg0).addReg(SP).addImm(8);
    // Save incoming sp to self stack reserve slot 1.
    BuildMI(MBB, MBBI, dl, TII.get(Tile::ST)).addReg(TempReg0).addReg(TempReg1);
  }

  // Emit ".cfi_def_cfa_offset STACKSIZE".
  MCSymbol *AdjustSPLabel = MMI.getContext().CreateTempSymbol();
  BuildMI(MBB, MBBI, dl, TII.get(TargetOpcode::PROLOG_LABEL))
      .addSym(AdjustSPLabel);
  DstML = MachineLocation(MachineLocation::VirtualFP);
  SrcML = MachineLocation(MachineLocation::VirtualFP, -StackSize);
  Moves.push_back(MachineMove(AdjustSPLabel, DstML, SrcML));

  const std::vector<CalleeSavedInfo> &CSI = MFI->getCalleeSavedInfo();

  if (CSI.size()) {
    // Find the instruction past the last instruction that saves a callee-saved
    // register to the stack.
    std::advance(MBBI, CSI.size());

    // Iterate over list of callee-saved registers and emit .cfi_offset
    // directives.
    MCSymbol *CSLabel = MMI.getContext().CreateTempSymbol();
    BuildMI(MBB, MBBI, dl, TII.get(TargetOpcode::PROLOG_LABEL)).addSym(CSLabel);

    for (std::vector<CalleeSavedInfo>::const_iterator I = CSI.begin(),
                                                      E = CSI.end();
         I != E; ++I) {
      int64_t Offset = MFI->getObjectOffset(I->getFrameIdx());
      unsigned Reg = I->getReg();

      DstML = MachineLocation(MachineLocation::VirtualFP, Offset);
      SrcML = MachineLocation(Reg);

      Moves.push_back(MachineMove(CSLabel, DstML, SrcML));
    }
  }

  // If framepointer enabled, set it to point to the stack pointer.
  if (hasFP(MF)) {
    BuildMI(MBB, MBBI, dl, TII.get(Tile::ADD), Tile::FP).addReg(SP)
        .addReg(ZERO);

    // Emit ".cfi_def_cfa_register $fp".
    MCSymbol *SetFPLabel = MMI.getContext().CreateTempSymbol();
    BuildMI(MBB, MBBI, dl, TII.get(TargetOpcode::PROLOG_LABEL))
        .addSym(SetFPLabel);
    DstML = MachineLocation(Tile::FP);
    SrcML = MachineLocation(MachineLocation::VirtualFP);
    Moves.push_back(MachineMove(SetFPLabel, DstML, SrcML));
  }
}

void TileFrameLowering::emitEpilogue(MachineFunction &MF,
                                     MachineBasicBlock &MBB) const {
  MachineBasicBlock::iterator MBBI = MBB.getLastNonDebugInstr();
  MachineFrameInfo *MFI = MF.getFrameInfo();
  const TileInstrInfo &TII =
      *static_cast<const TileInstrInfo *>(MF.getTarget().getInstrInfo());
  DebugLoc dl = MBBI->getDebugLoc();
  unsigned SP = Tile::SP;
  unsigned FP = Tile::FP;
  unsigned LR = Tile::LR;
  unsigned ZERO = Tile::ZERO;
  unsigned TempReg = Tile::R10;

  if (hasFP(MF)) {
    // Find the first instruction that restores a callee-saved register.
    MachineBasicBlock::iterator I = MBBI;

    for (unsigned i = 0, e = MFI->getCalleeSavedInfo().size(); i != e; ++i)
      --I;

    // Insert instruction "move $sp, $fp" at this location.
    BuildMI(MBB, I, dl, TII.get(Tile::ADD), SP).addReg(FP).addReg(ZERO);
  }

  // Get the number of bytes from FrameInfo.
  uint64_t StackSize = MFI->getStackSize();

  if (!StackSize)
    return;

  addImmR(SP, TempReg, StackSize, TII, MBB, MBBI, dl);

  if (MFI->hasCalls())
    BuildMI(MBB, MBBI, dl, TII.get(Tile::LD), LR).addReg(SP);
}

bool TileFrameLowering::spillCalleeSavedRegisters(
    MachineBasicBlock &MBB, MachineBasicBlock::iterator MI,
    const std::vector<CalleeSavedInfo> &CSI,
    const TargetRegisterInfo *TRI) const {
  MachineFunction *MF = MBB.getParent();
  MachineBasicBlock *EntryBlock = MF->begin();
  const TargetInstrInfo &TII = *MF->getTarget().getInstrInfo();

  for (unsigned i = 0, e = CSI.size(); i != e; ++i) {
    // Add the callee-saved register as live-in. Do not add if the register is
    // RA and return address is taken, because it has already been added in
    // method TileTargetLowering::LowerRETURNADDR.
    // It's killed at the spill, unless the register is LR and return address
    // is taken.
    unsigned Reg = CSI[i].getReg();
    bool IsLRAndRetAddrIsTaken =
        (Reg == Tile::LR) && MF->getFrameInfo()->isReturnAddressTaken();
    if (!IsLRAndRetAddrIsTaken)
      EntryBlock->addLiveIn(Reg);

    // Insert the spill to the stack frame.
    bool IsKill = !IsLRAndRetAddrIsTaken;
    const TargetRegisterClass *RC = TRI->getMinimalPhysRegClass(Reg);
    TII.storeRegToStackSlot(*EntryBlock, MI, Reg, IsKill, CSI[i].getFrameIdx(),
                            RC, TRI);
  }

  return true;
}

int TileFrameLowering::getFrameIndexOffset(const MachineFunction &MF,
                                           int FI) const {
  const MachineFrameInfo *MFI = MF.getFrameInfo();
  int AdjustedOffset = MFI->getObjectOffset(FI) + MFI->getOffsetAdjustment();
  return hasFP(MF) ? AdjustedOffset : AdjustedOffset + MFI->getStackSize();
}

// This function eliminate ADJCALLSTACKDOWN,
// ADJCALLSTACKUP pseudo instructions
void TileFrameLowering::eliminateCallFramePseudoInstr(
    MachineFunction &MF, MachineBasicBlock &MBB,
    MachineBasicBlock::iterator I) const {
  // Simply discard ADJCALLSTACKDOWN, ADJCALLSTACKUP instructions.
  MBB.erase(I);
}

void TileFrameLowering::processFunctionBeforeCalleeSavedScan(
    MachineFunction &MF, RegScavenger *RS) const {
  MachineRegisterInfo &MRI = MF.getRegInfo();
  TileFunctionInfo *TileFI = MF.getInfo<TileFunctionInfo>();

  if (hasFP(MF))
    MRI.setPhysRegUsed(Tile::FP);

  if (TileFI->globalBaseRegSet())
    MRI.setPhysRegUsed(TileFI->getGlobalBaseReg());

  if (TileFI->linkRegSet())
    MRI.setPhysRegUsed(TileFI->getLinkReg());
}
