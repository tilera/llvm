//===-- TileRegisterInfo.cpp - TILE Register Information -== --------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the TILE implementation of the TargetRegisterInfo class.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "tile-reg-info"

#include "TileRegisterInfo.h"
#include "Tile.h"
#include "TileSubtarget.h"
#include "TileMachineFunction.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/Function.h"
#include "llvm/CodeGen/ValueTypes.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/Target/TargetFrameLowering.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetOptions.h"
#include "llvm/Target/TargetInstrInfo.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/ADT/BitVector.h"
#include "llvm/ADT/STLExtras.h"

#define GET_REGINFO_TARGET_DESC
#include "TileGenRegisterInfo.inc"

using namespace llvm;

TileRegisterInfo::TileRegisterInfo(const TileSubtarget &ST,
                                   const TargetInstrInfo &tii)
    : TileGenRegisterInfo(Tile::LR), Subtarget(ST), TII(tii) {}

unsigned TileRegisterInfo::getPICCallReg() { return Tile::R29; }

//===----------------------------------------------------------------------===//
// Callee Saved Registers methods.
//===----------------------------------------------------------------------===//

// Tile Callee Saved Registers.
const uint16_t *
TileRegisterInfo::getCalleeSavedRegs(const MachineFunction *MF) const {
  return CSR_Tile_SaveList;
}

const uint32_t *TileRegisterInfo::getCallPreservedMask(CallingConv::ID) const {
  return CSR_Tile_RegMask;
}

BitVector TileRegisterInfo::getReservedRegs(const MachineFunction &MF) const {
  static const uint16_t ReservedCPURegs[] = { Tile::R49, Tile::FP, Tile::TP,
                                              Tile::SP, Tile::LR, Tile::ZERO };

  static const uint16_t ReservedCPU32Regs[] = { Tile::R49_32, Tile::FP_32,
                                                Tile::TP_32, Tile::SP_32,
                                                Tile::LR_32, Tile::ZERO_32 };

  BitVector Reserved(getNumRegs());
  typedef TargetRegisterClass::iterator RegIter;

  for (unsigned I = 0; I < array_lengthof(ReservedCPURegs); ++I)
    Reserved.set(ReservedCPURegs[I]);

  for (unsigned I = 0; I < array_lengthof(ReservedCPU32Regs); ++I)
    Reserved.set(ReservedCPU32Regs[I]);

  // If GP is dedicated as a global base register, reserve it.
  if (MF.getInfo<TileFunctionInfo>()->globalBaseRegFixed()) {
    Reserved.set(Tile::R51);
    Reserved.set(Tile::R50);
    Reserved.set(Tile::R51_32);
    Reserved.set(Tile::R50_32);
  }

  return Reserved;
}

bool TileRegisterInfo::requiresRegisterScavenging(
    const MachineFunction &MF) const {
  return true;
}

// FrameIndex represent objects inside a abstract stack.
// We must replace FrameIndex with an stack/frame pointer
// direct reference.
void TileRegisterInfo::eliminateFrameIndex(MachineBasicBlock::iterator II,
                                           int SPAdj, unsigned FIOperandNum,
                                           RegScavenger *RS) const {

  assert(SPAdj == 0 && "Unexpected");

  MachineInstr &MI = *II;
  MachineBasicBlock &MBB = *MI.getParent();
  MachineFunction &MF = *MBB.getParent();
  MachineFrameInfo *MFI = MF.getFrameInfo();
  DebugLoc DL = MI.getDebugLoc();
  const std::vector<CalleeSavedInfo> &CSI = MFI->getCalleeSavedInfo();
  int MinCSFI = 0;
  int MaxCSFI = -1;

  if (CSI.size()) {
    MinCSFI = CSI.front().getFrameIdx();
    MaxCSFI = CSI.back().getFrameIdx();
  }

  int Opc = MI.getOpcode();

  unsigned DestReg = 0;
  MachineOperand *FrameIndexOp = 0;

  if (Opc == Tile::TileFI) {
    DestReg = MI.getOperand(0).getReg();
    FrameIndexOp = &MI.getOperand(1);
  } else if (Opc == Tile::ST || Opc == Tile::ST4 || Opc == Tile::LD ||
             Opc == Tile::LD4S32 || MI.isDebugValue()) {
    DestReg = Tile::R49;
    FrameIndexOp = &MI.getOperand(FIOperandNum);
  }

  unsigned StackReg = 0;
  int64_t Offset = 0;
  int FrameIndex = FrameIndexOp->getIndex();

  if (FrameIndex >= MinCSFI && FrameIndex <= MaxCSFI)
    StackReg = Tile::SP;
  else
    StackReg = getFrameRegister(MF);

  Offset = MFI->getObjectOffset(FrameIndex) + MFI->getOffsetAdjustment() +
           MFI->getStackSize();

  if (MI.isDebugValue()) {
    MI.getOperand(FIOperandNum).ChangeToRegister(StackReg, false);
    MI.getOperand(FIOperandNum + 1).ChangeToImmediate(Offset);
    return;
  }

  if (isInt<8>(Offset))
    BuildMI(MBB, II, DL, TII.get(Tile::ADDI), DestReg).addReg(StackReg)
        .addImm(Offset);
  else if (isInt<16>(Offset))
    BuildMI(MBB, II, DL, TII.get(Tile::ADDLI), DestReg).addReg(StackReg)
        .addImm(Offset);
  else if (isInt<32>(Offset)) {
    BuildMI(MBB, II, DL, TII.get(Tile::MOVELI), DestReg)
        .addImm((((uint64_t) Offset) >> 16) & 0xFFFF);
    BuildMI(MBB, II, DL, TII.get(Tile::SHL16INSLI), DestReg).addReg(DestReg)
        .addImm(Offset & ((1 << 16) - 1));
    BuildMI(MBB, II, DL, TII.get(Tile::ADD), DestReg).addReg(DestReg)
        .addReg(StackReg);
  } else {
    assert(isInt<64>(Offset) && "do not support Offset > 32bit yet");
    BuildMI(MBB, II, DL, TII.get(Tile::MOVELI), DestReg)
        .addImm((((uint64_t) Offset) >> 32) & 0xFFFF);
    BuildMI(MBB, II, DL, TII.get(Tile::SHL16INSLI), DestReg).addReg(DestReg)
        .addImm((((uint64_t) Offset) >> 16) & 0xFFFF);
    BuildMI(MBB, II, DL, TII.get(Tile::SHL16INSLI), DestReg).addReg(DestReg)
        .addImm(Offset & ((1 << 16) - 1));
    BuildMI(MBB, II, DL, TII.get(Tile::ADD), DestReg).addReg(DestReg)
        .addReg(StackReg);
  }

  switch (Opc) {
  default:
    llvm_unreachable("FrameIndex in unexpected instruction!");
  case Tile::TileFI:
    MI.eraseFromParent();
    break;
  case Tile::ST:
  case Tile::ST4:
  case Tile::LD:
  case Tile::LD4S32:
    FrameIndexOp->ChangeToRegister(DestReg, false);
    break;
  }
}

unsigned TileRegisterInfo::getFrameRegister(const MachineFunction &MF) const {
  const TargetFrameLowering *TFI = MF.getTarget().getFrameLowering();
  return TFI->hasFP(MF) ? Tile::FP : Tile::SP;
}
