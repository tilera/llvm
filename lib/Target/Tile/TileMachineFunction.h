//===-- TileMachineFunctionInfo.h - Private data used for Tile ----*- C++ -*-=//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file declares the Tile specific subclass of MachineFunctionInfo.
//
//===----------------------------------------------------------------------===//

#ifndef TILE_MACHINE_FUNCTION_INFO_H
#define TILE_MACHINE_FUNCTION_INFO_H

#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include <utility>

namespace llvm {

class TileFunctionInfo : public MachineFunctionInfo {
  virtual void anchor();

  MachineFunction &MF;
  // Some subtargets require that sret lowering includes
  // returning the value of the returned struct in a register. This field
  // holds the virtual register into which the sret argument is passed.
  unsigned SRetReturnReg;

  // Keeps track of the virtual register initialized for
  // use as the global base register. This is used for
  // PIC in some PIC relocation models.
  unsigned GlobalBaseReg;

  // This is used to hold the next PC, for PIC purpose.
  unsigned LinkReg;

  // FrameIndex for start of varargs area.
  int VarArgsFrameIndex;
  // The FrameIndex which kept the value of VarArgsFrameIndex.
  int VarArgsResSlot;

  // Frame index of dynamically allocated stack area.
  mutable int DynAllocFI;
  unsigned MaxCallFrameSize;

public:
  TileFunctionInfo(MachineFunction &MF)
      : MF(MF), SRetReturnReg(0), GlobalBaseReg(0), LinkReg(0),
        VarArgsFrameIndex(0), VarArgsResSlot(0), DynAllocFI(0),
        MaxCallFrameSize(0) {}

  // The first call to this function creates a frame object for dynamically
  // allocated stack area.
  int getDynAllocFI() const {
    if (!DynAllocFI)
      DynAllocFI = MF.getFrameInfo()->CreateFixedObject(8, 0, true);

    return DynAllocFI;
  }
  bool isDynAllocFI(int FI) const { return DynAllocFI && DynAllocFI == FI; }

  unsigned getSRetReturnReg() const { return SRetReturnReg; }
  void setSRetReturnReg(unsigned Reg) { SRetReturnReg = Reg; }

  bool globalBaseRegFixed() const;
  bool globalBaseRegSet() const;
  unsigned getGlobalBaseReg();
  bool linkRegFixed() const;
  bool linkRegSet() const;
  unsigned getLinkReg();

  int getVarArgsFrameIndex() const { return VarArgsFrameIndex; }
  void setVarArgsFrameIndex(int Index) { VarArgsFrameIndex = Index; }
  int getVarArgsResSlot() const { return VarArgsResSlot; }
  void setVarArgsResSlot(int Index) { VarArgsResSlot = Index; }
  unsigned getMaxCallFrameSize() const { return MaxCallFrameSize; }
  void setMaxCallFrameSize(unsigned S) { MaxCallFrameSize = S; }
};

} // end of namespace llvm

#endif // TILE_MACHINE_FUNCTION_INFO_H
