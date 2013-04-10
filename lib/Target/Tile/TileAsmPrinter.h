//===-- TileAsmPrinter.h - Tile LLVM Assembly Printer ----------*- C++ -*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// Tile Assembly printer class.
//
//===----------------------------------------------------------------------===//

#ifndef TILEASMPRINTER_H
#define TILEASMPRINTER_H

#include "Tile.h"
#include "TileMachineFunction.h"
#include "TileMCInstLower.h"
#include "TileSubtarget.h"
#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/Support/Compiler.h"
#include "llvm/Target/TargetMachine.h"

namespace llvm {
class MCStreamer;
class MachineInstr;
class MachineBasicBlock;
class Module;
class raw_ostream;

class LLVM_LIBRARY_VISIBILITY TileAsmPrinter : public AsmPrinter {

public:

  const TileSubtarget *Subtarget;
  const TileFunctionInfo *TileFI;

  explicit TileAsmPrinter(TargetMachine &TM, MCStreamer &Streamer)
      : AsmPrinter(TM, Streamer) {
    Subtarget = &TM.getSubtarget<TileSubtarget>();
  }

  virtual const char *getPassName() const { return "Tile Assembly Printer"; }

  virtual bool runOnMachineFunction(MachineFunction &MF);

  void EmitInstruction(const MachineInstr *MI);
  void EmitJumpTable(const MachineInstr *MI);
  virtual void EmitFunctionEntryLabel();
  virtual bool isBlockOnlyReachableByFallthrough(
      const MachineBasicBlock *MBB) const;
  bool PrintAsmOperand(const MachineInstr *MI, unsigned OpNo,
                       unsigned AsmVariant, const char *ExtraCode,
                       raw_ostream &O);
  bool PrintAsmMemoryOperand(const MachineInstr *MI, unsigned OpNum,
                             unsigned AsmVariant, const char *ExtraCode,
                             raw_ostream &O);
  void printOperand(const MachineInstr *MI, int opNum, raw_ostream &O);
  void printUnsignedImm(const MachineInstr *MI, int opNum, raw_ostream &O);
  void EmitStartOfAsmFile(Module &M);
  virtual MachineLocation getDebugValueLocation(const MachineInstr *MI) const;
  void PrintDebugValueComment(const MachineInstr *MI, raw_ostream &OS);
  MCSymbol *GetTileJTIName(unsigned uid) const;
};
}

#endif
