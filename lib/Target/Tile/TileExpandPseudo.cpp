//===--  TileExpandPseudo.cpp - Expand Pseudo Instructions ----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This pass expands pseudo instructions into target instructions after register
// allocation but before post-RA scheduling.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "tile-expand-pseudo"

#include "Tile.h"
#include "TileTargetMachine.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/Target/TargetInstrInfo.h"
#include "llvm/ADT/Statistic.h"

using namespace llvm;

namespace {
struct TileExpandPseudo : public MachineFunctionPass {

  TargetMachine &TM;
  const TargetInstrInfo *TII;

  static char ID;
  TileExpandPseudo(TargetMachine &tm)
      : MachineFunctionPass(ID), TM(tm), TII(tm.getInstrInfo()) {}

  virtual const char *getPassName() const {
    return "Tile PseudoInstrs Expansion";
  }

  bool runOnMachineFunction(MachineFunction &F);
  bool runOnMachineBasicBlock(MachineBasicBlock &MBB);

private:
  void ExpandBuildPairF64(MachineBasicBlock &, MachineBasicBlock::iterator);
  void
  ExpandExtractElementF64(MachineBasicBlock &, MachineBasicBlock::iterator);
};
char TileExpandPseudo::ID = 0;
} // end of anonymous namespace

bool TileExpandPseudo::runOnMachineFunction(MachineFunction &F) {
  bool Changed = false;

  for (MachineFunction::iterator I = F.begin(); I != F.end(); ++I)
    Changed |= runOnMachineBasicBlock(*I);

  return Changed;
}

bool TileExpandPseudo::runOnMachineBasicBlock(MachineBasicBlock &MBB) {

  bool Changed = false;
  MachineFunction &MF = *MBB.getParent();
  MachineFrameInfo *MFI = MF.getFrameInfo();
  TileFunctionInfo *TFI = MF.getInfo<TileFunctionInfo>();
  for (MachineBasicBlock::iterator I = MBB.begin(); I != MBB.end();) {
    const MCInstrDesc &MCId = I->getDesc();

    switch (MCId.getOpcode()) {
    default:
      ++I;
      continue;
    case Tile::VAARG_SP:
      BuildMI(MBB, I, I->getDebugLoc(), TII->get(Tile::ADDLI),
              I->getOperand(0).getReg())
          .addReg(I->getOperand(1).getReg())
          .addImm(MFI->getStackSize() + MFI->getOffsetAdjustment());
      break;

    // The addr alloca returned should by adjusted by the size
    // of Tile 16bytes zone and arg outgoing zone.
    case Tile::ALLOCA_ADDR:
      BuildMI(MBB, I, I->getDebugLoc(), TII->get(Tile::ADDLI),
              I->getOperand(0).getReg())
          .addReg(I->getOperand(1).getReg())
          .addImm(TFI->getMaxCallFrameSize() + (MFI->hasCalls() ? 16 : 0));
      break;

    case Tile::ALLOCA_SP: {
      unsigned SrcSP = Tile::SP;
      if (MFI->hasCalls())
        SrcSP = I->getOperand(2).getReg();

      BuildMI(MBB, I, I->getDebugLoc(), TII->get(Tile::ADD),
              I->getOperand(0).getReg()).addReg(Tile::ZERO).addReg(SrcSP);
      break;
    }

    case Tile::FSINGLE_CMP_LTO:
    case Tile::FSINGLE_CMP_LEO:
    case Tile::FSINGLE_CMP_GTO:
    case Tile::FSINGLE_CMP_GEO:
    case Tile::FSINGLE_CMP_EQO:
    case Tile::FSINGLE_CMP_NEO:
    case Tile::FDOUBLE_CMP_LTO:
    case Tile::FDOUBLE_CMP_LEO:
    case Tile::FDOUBLE_CMP_GTO:
    case Tile::FDOUBLE_CMP_GEO:
    case Tile::FDOUBLE_CMP_EQO:
    case Tile::FDOUBLE_CMP_NEO:
    case Tile::FSINGLE_CMP_LTO32:
    case Tile::FSINGLE_CMP_LEO32:
    case Tile::FSINGLE_CMP_GTO32:
    case Tile::FSINGLE_CMP_GEO32:
    case Tile::FSINGLE_CMP_EQO32:
    case Tile::FSINGLE_CMP_NEO32:
    case Tile::FDOUBLE_CMP_LTO32:
    case Tile::FDOUBLE_CMP_LEO32:
    case Tile::FDOUBLE_CMP_GTO32:
    case Tile::FDOUBLE_CMP_GEO32:
    case Tile::FDOUBLE_CMP_EQO32:
    case Tile::FDOUBLE_CMP_NEO32:
      if (!TM.Options.NoNaNsFPMath)
        llvm_unreachable("All SETOXX should be expanded to SETO and SETXX");

    case Tile::FSINGLE_CMP_LT:
    case Tile::FSINGLE_CMP_LE:
    case Tile::FSINGLE_CMP_GT:
    case Tile::FSINGLE_CMP_GE:
    case Tile::FSINGLE_CMP_EQ:
    case Tile::FSINGLE_CMP_NE:
    case Tile::FSINGLE_CMP_LT32:
    case Tile::FSINGLE_CMP_LE32:
    case Tile::FSINGLE_CMP_GT32:
    case Tile::FSINGLE_CMP_GE32:
    case Tile::FSINGLE_CMP_EQ32:
    case Tile::FSINGLE_CMP_NE32:
    case Tile::FDOUBLE_CMP_LT:
    case Tile::FDOUBLE_CMP_LE:
    case Tile::FDOUBLE_CMP_GT:
    case Tile::FDOUBLE_CMP_GE:
    case Tile::FDOUBLE_CMP_EQ:
    case Tile::FDOUBLE_CMP_NE:
    case Tile::FDOUBLE_CMP_LT32:
    case Tile::FDOUBLE_CMP_LE32:
    case Tile::FDOUBLE_CMP_GT32:
    case Tile::FDOUBLE_CMP_GE32:
    case Tile::FDOUBLE_CMP_EQ32:
    case Tile::FDOUBLE_CMP_NE32: {

      unsigned DestReg = I->getOperand(0).getReg();
      unsigned SraReg = I->getOperand(1).getReg();
      unsigned SrbReg = I->getOperand(2).getReg();
      unsigned OldOpcode = MCId.getOpcode();
      unsigned NewOpcode = Tile::FDOUBLE_ADD_FLAGS;
      // Bit Name
      // 25  unorder
      // 26  lt
      // 27  le
      // 28  gt
      // 29  ge
      // 30  eq
      // 31  ne
      int64_t FPResOff[6] = { 30, 29, 28, 27, 26, 31 };
      int64_t BitOff;
      if (OldOpcode >= Tile::FSINGLE_CMP_EQ) {
        NewOpcode = Tile::FSINGLE_ADD1;
        BitOff = FPResOff[(OldOpcode - Tile::FSINGLE_CMP_EQ) / 6];
      } else
        BitOff = FPResOff[(OldOpcode - Tile::FDOUBLE_CMP_EQ) / 6];
      BuildMI(MBB, I, I->getDebugLoc(), TII->get(NewOpcode), DestReg)
          .addReg(SraReg).addReg(SrbReg);
      BuildMI(MBB, I, I->getDebugLoc(), TII->get(Tile::BFEXTU), DestReg)
          .addReg(DestReg).addImm(BitOff).addImm(BitOff);
      break;
    }

    case Tile::FSINGLE_CMP_LTU:
    case Tile::FSINGLE_CMP_LEU:
    case Tile::FSINGLE_CMP_GTU:
    case Tile::FSINGLE_CMP_GEU:
    case Tile::FSINGLE_CMP_EQU:
    case Tile::FSINGLE_CMP_NEU:
    case Tile::FDOUBLE_CMP_LTU:
    case Tile::FDOUBLE_CMP_LEU:
    case Tile::FDOUBLE_CMP_GTU:
    case Tile::FDOUBLE_CMP_GEU:
    case Tile::FDOUBLE_CMP_EQU:
    case Tile::FDOUBLE_CMP_NEU:
    case Tile::FSINGLE_CMP_LTU32:
    case Tile::FSINGLE_CMP_LEU32:
    case Tile::FSINGLE_CMP_GTU32:
    case Tile::FSINGLE_CMP_GEU32:
    case Tile::FSINGLE_CMP_EQU32:
    case Tile::FSINGLE_CMP_NEU32:
    case Tile::FDOUBLE_CMP_LTU32:
    case Tile::FDOUBLE_CMP_LEU32:
    case Tile::FDOUBLE_CMP_GTU32:
    case Tile::FDOUBLE_CMP_GEU32:
    case Tile::FDOUBLE_CMP_EQU32:
    case Tile::FDOUBLE_CMP_NEU32: {

      unsigned DestReg = I->getOperand(0).getReg();
      unsigned SraReg = I->getOperand(1).getReg();
      unsigned SrbReg = I->getOperand(2).getReg();
      unsigned OldOpcode = MCId.getOpcode();
      unsigned NewOpcode = Tile::FDOUBLE_ADD_FLAGS;
      // Bit Name
      // 25  unorder
      // 26  lt
      // 27  le
      // 28  gt
      // 29  ge
      // 30  eq
      // 31  ne
      int64_t FPResOff[6] = { 30, 29, 28, 27, 26, 31 };
      int64_t BitOff;
      int64_t BitMask;
      if (OldOpcode >= Tile::FSINGLE_CMP_EQ) {
        NewOpcode = Tile::FSINGLE_ADD1;
        BitOff = FPResOff[(OldOpcode - Tile::FSINGLE_CMP_EQ) / 6];
      } else
        BitOff = FPResOff[(OldOpcode - Tile::FDOUBLE_CMP_EQ) / 6];

      BuildMI(MBB, I, I->getDebugLoc(), TII->get(NewOpcode), DestReg)
          .addReg(SraReg).addReg(SrbReg);
      if (TM.Options.NoNaNsFPMath) {
        BuildMI(MBB, I, I->getDebugLoc(), TII->get(Tile::BFEXTU), DestReg)
            .addReg(DestReg).addImm(BitOff).addImm(BitOff);
        break;
      }

      BitMask = (1LL << (BitOff - 25)) | 1LL;
      BuildMI(MBB, I, I->getDebugLoc(), TII->get(Tile::SHRUI), DestReg)
          .addReg(DestReg).addImm(25);
      BuildMI(MBB, I, I->getDebugLoc(), TII->get(Tile::ANDI), DestReg)
          .addReg(DestReg).addImm(BitMask);
      BuildMI(MBB, I, I->getDebugLoc(), TII->get(Tile::CMPNE), DestReg)
          .addReg(DestReg).addReg(Tile::ZERO);
      break;
    }

    case Tile::FSINGLE_CMP_O:
    case Tile::FDOUBLE_CMP_O:
    case Tile::FSINGLE_CMP_UO:
    case Tile::FDOUBLE_CMP_UO:
    case Tile::FSINGLE_CMP_O32:
    case Tile::FDOUBLE_CMP_O32:
    case Tile::FSINGLE_CMP_UO32:
    case Tile::FDOUBLE_CMP_UO32: {

      unsigned DestReg = I->getOperand(0).getReg();
      unsigned SraReg = I->getOperand(1).getReg();
      unsigned SrbReg = I->getOperand(2).getReg();
      unsigned OldOpcode = MCId.getOpcode();
      unsigned NewOpcode1 = Tile::FDOUBLE_ADD_FLAGS;
      unsigned NewOpcode2 = Tile::CMPNE;

      if (OldOpcode >= Tile::FSINGLE_CMP_O)
        NewOpcode1 = Tile::FSINGLE_ADD1;

      if (OldOpcode == Tile::FSINGLE_CMP_O ||
          OldOpcode == Tile::FDOUBLE_CMP_O ||
          OldOpcode == Tile::FSINGLE_CMP_O32 ||
          OldOpcode == Tile::FDOUBLE_CMP_O32)
        NewOpcode2 = Tile::CMPEQ;

      BuildMI(MBB, I, I->getDebugLoc(), TII->get(NewOpcode1), DestReg)
          .addReg(SraReg).addReg(SrbReg);
      BuildMI(MBB, I, I->getDebugLoc(), TII->get(Tile::SHRUI), DestReg)
          .addReg(DestReg).addImm(25);
      BuildMI(MBB, I, I->getDebugLoc(), TII->get(Tile::ANDI), DestReg)
          .addReg(DestReg).addImm(0x1);
      BuildMI(MBB, I, I->getDebugLoc(), TII->get(NewOpcode2), DestReg)
          .addReg(DestReg).addReg(Tile::ZERO);
      break;
    }

    }

    // Delete original instr.
    MBB.erase(I++);
    Changed = true;
  }

  return Changed;
}

/// Returns a pass that expands pseudo instrs into real instrs.
FunctionPass *llvm::createTileExpandPseudoPass(TileTargetMachine &tm) {
  return new TileExpandPseudo(tm);
}
