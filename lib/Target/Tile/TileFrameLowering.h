//===-- TileFrameLowering.h - Define frame lowering for Tile ----*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef TILE_FRAMEINFO_H
#define TILE_FRAMEINFO_H

#include "Tile.h"
#include "TileSubtarget.h"
#include "llvm/Target/TargetFrameLowering.h"

namespace llvm {
class TileSubtarget;

class TileFrameLowering : public TargetFrameLowering {
protected:
  const TileSubtarget &STI;

public:
  explicit TileFrameLowering(const TileSubtarget &sti)
      : TargetFrameLowering(StackGrowsDown, 8, 0), STI(sti) {}

  // Insert prolog and epilog code into the function.
  void emitPrologue(MachineFunction &MF) const;
  void emitEpilogue(MachineFunction &MF, MachineBasicBlock &MBB) const;

  void eliminateCallFramePseudoInstr(MachineFunction &MF,
                                     MachineBasicBlock &MBB,
                                     MachineBasicBlock::iterator I) const;

  bool spillCalleeSavedRegisters(MachineBasicBlock &MBB,
                                 MachineBasicBlock::iterator MI,
                                 const std::vector<CalleeSavedInfo> &CSI,
                                 const TargetRegisterInfo *TRI) const;

  bool hasFP(const MachineFunction &MF) const;
  bool hasReservedCallFrame(const MachineFunction &MF) const;

  int getFrameIndexOffset(const MachineFunction &MF, int FI) const;
  void processFunctionBeforeCalleeSavedScan(MachineFunction &MF,
                                            RegScavenger *RS) const;
};

} // End llvm namespace

#endif
