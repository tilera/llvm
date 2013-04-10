//===-- TileRegisterInfo.h - Tile Register Information Impl -----*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the Tile implementation of the TargetRegisterInfo class.
//
//===----------------------------------------------------------------------===//

#ifndef TILEREGISTERINFO_H
#define TILEREGISTERINFO_H

#include "Tile.h"
#include "llvm/Target/TargetRegisterInfo.h"

#define GET_REGINFO_HEADER
#include "TileGenRegisterInfo.inc"

namespace llvm {
class TileSubtarget;
class TargetInstrInfo;
class Type;

struct TileRegisterInfo : public TileGenRegisterInfo {
  const TileSubtarget &Subtarget;
  const TargetInstrInfo &TII;

  TileRegisterInfo(const TileSubtarget &Subtarget, const TargetInstrInfo &tii);

  // Given the enum value for some register,
  // return the number that it corresponds to.
  static unsigned getRegisterNumbering(unsigned RegEnum);

  /// Get PIC indirect call register.
  static unsigned getPICCallReg();

  /// Adjust the Tile stack frame..
  void adjustTileStackFrame(MachineFunction &MF) const;

  /// Code Generation virtual methods.
  const uint16_t *getCalleeSavedRegs(const MachineFunction *MF = 0) const;
  const uint32_t *getCallPreservedMask(CallingConv::ID) const;

  BitVector getReservedRegs(const MachineFunction &MF) const;

  virtual bool requiresRegisterScavenging(const MachineFunction &MF) const;

  /// Stack Frame Processing Methods.
  void eliminateFrameIndex(MachineBasicBlock::iterator II, int SPAdj,
                           unsigned FIOperandNum,
                           RegScavenger *RS = NULL) const;

  void processFunctionBeforeFrameFinalized(MachineFunction &MF,
                                           RegScavenger *RS = NULL) const;

  /// Debug information queries.
  unsigned getFrameRegister(const MachineFunction &MF) const;
};

} // end namespace llvm

#endif
