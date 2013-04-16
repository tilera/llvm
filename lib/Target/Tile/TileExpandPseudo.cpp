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

    case Tile::FSINGLE_CMP_OLT:
    case Tile::FSINGLE_CMP_OLE:
    case Tile::FSINGLE_CMP_OGT:
    case Tile::FSINGLE_CMP_OGE:
    case Tile::FSINGLE_CMP_OEQ:
    case Tile::FSINGLE_CMP_ONE:
    case Tile::FSINGLE_CMP_ULT:
    case Tile::FSINGLE_CMP_ULE:
    case Tile::FSINGLE_CMP_UGT:
    case Tile::FSINGLE_CMP_UGE:
    case Tile::FSINGLE_CMP_UEQ:
    case Tile::FSINGLE_CMP_UNE:
    case Tile::FDOUBLE_CMP_OLT:
    case Tile::FDOUBLE_CMP_OLE:
    case Tile::FDOUBLE_CMP_OGT:
    case Tile::FDOUBLE_CMP_OGE:
    case Tile::FDOUBLE_CMP_OEQ:
    case Tile::FDOUBLE_CMP_ONE:
    case Tile::FDOUBLE_CMP_ULT:
    case Tile::FDOUBLE_CMP_ULE:
    case Tile::FDOUBLE_CMP_UGT:
    case Tile::FDOUBLE_CMP_UGE:
    case Tile::FDOUBLE_CMP_UEQ:
    case Tile::FDOUBLE_CMP_UNE: {
      unsigned DestReg = I->getOperand(0).getReg();
      unsigned SraReg = I->getOperand(1).getReg();
      unsigned SrbReg = I->getOperand(2).getReg();
      unsigned OldOpcode = MCId.getOpcode();
      unsigned NewOpcode = Tile::FDOUBLE_ADD_FLAGS;
      // Bit Name
      // 26  lt
      // 27  le
      // 28  gt
      // 29  ge
      // 30  eq
      // 31  ne
      int64_t FPResOff[6] = { 30, 29, 28, 27, 26, 31 };
      int64_t BitOff;
      if (OldOpcode >= Tile::FSINGLE_CMP_OEQ) {
        NewOpcode = Tile::FSINGLE_ADD1;
        if (OldOpcode >= Tile::FSINGLE_CMP_UEQ)
          BitOff = FPResOff[OldOpcode - Tile::FSINGLE_CMP_UEQ];
        else
          BitOff = FPResOff[OldOpcode - Tile::FSINGLE_CMP_OEQ];
      } else if (OldOpcode >= Tile::FDOUBLE_CMP_UEQ)
        BitOff = FPResOff[OldOpcode - Tile::FDOUBLE_CMP_UEQ];
      else
        BitOff = FPResOff[OldOpcode - Tile::FDOUBLE_CMP_OEQ];
      BuildMI(MBB, I, I->getDebugLoc(), TII->get(NewOpcode), DestReg)
          .addReg(SraReg).addReg(SrbReg);
      BuildMI(MBB, I, I->getDebugLoc(), TII->get(Tile::BFEXTU), DestReg)
          .addReg(DestReg).addImm(BitOff).addImm(BitOff);
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
