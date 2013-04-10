//===-- TileInstrInfo.h - Tile Instruction Information ----------*- C++ -*-===//
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

#ifndef TILEINSTRUCTIONINFO_H
#define TILEINSTRUCTIONINFO_H

#include "Tile.h"
#include "TileRegisterInfo.h"
#include "MCTargetDesc/TileBaseInfo.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Target/TargetInstrInfo.h"

#define GET_INSTRINFO_HEADER
#include "TileGenInstrInfo.inc"

namespace llvm {

namespace Tile {
// Return the inverse of the specified opcode, e.g. turning BEQ to BNE.
unsigned GetOppositeBranchOpc(unsigned Opc);
}

class TileInstrInfo : public TileGenInstrInfo {
  TileTargetMachine &TM;
  const TileRegisterInfo RI;
  unsigned UncondBrOpc;
public:
  explicit TileInstrInfo(TileTargetMachine &TM);

  // TargetInstrInfo is a superset of MRegister info.  As such, whenever
  // a client has an instance of instruction info, it should always be
  // able to get register info as well (through this method).
  virtual const TileRegisterInfo &getRegisterInfo() const;

  // If the specified machine instruction is a direct load from a stack slot,
  // return the virtual or physical register number of the destination along
  // with the FrameIndex of the loaded stack slot. If not, return 0.
  // This predicate must return 0 if the instruction has any side effects other
  // than loading from the stack slot.
  virtual unsigned isLoadFromStackSlot(const MachineInstr *MI,
                                       int &FrameIndex) const;

  // If the specified machine instruction is a direct store to a stack slot,
  // return the virtual or physical register number of the source reg along
  // with the FrameIndex of the loaded stack slot.  If not, return 0.
  // This predicate must return 0 if the instruction has any side effects
  // other than storing to the stack slot.
  virtual unsigned isStoreToStackSlot(const MachineInstr *MI,
                                      int &FrameIndex) const;

  // Branch Analysis.
  virtual bool AnalyzeBranch(
      MachineBasicBlock &MBB, MachineBasicBlock *&TBB, MachineBasicBlock *&FBB,
      SmallVectorImpl<MachineOperand> &Cond, bool AllowModify) const;
  virtual unsigned RemoveBranch(MachineBasicBlock &MBB) const;

private:
  void BuildCondBr(MachineBasicBlock &MBB, MachineBasicBlock *TBB, DebugLoc DL,
                   const SmallVectorImpl<MachineOperand> &Cond) const;

public:
  virtual unsigned InsertBranch(
      MachineBasicBlock &MBB, MachineBasicBlock *TBB, MachineBasicBlock *FBB,
      const SmallVectorImpl<MachineOperand> &Cond, DebugLoc DL) const;
  virtual void copyPhysReg(
      MachineBasicBlock &MBB, MachineBasicBlock::iterator MI, DebugLoc DL,
      unsigned DestReg, unsigned SrcReg, bool KillSrc) const;
  virtual void storeRegToStackSlot(
      MachineBasicBlock &MBB, MachineBasicBlock::iterator MBBI, unsigned SrcReg,
      bool isKill, int FrameIndex, const TargetRegisterClass *RC,
      const TargetRegisterInfo *TRI) const;

  virtual void loadRegFromStackSlot(
      MachineBasicBlock &MBB, MachineBasicBlock::iterator MBBI,
      unsigned DestReg, int FrameIndex, const TargetRegisterClass *RC,
      const TargetRegisterInfo *TRI) const;

  virtual MachineInstr *
  emitFrameIndexDebugValue(MachineFunction &MF, int FrameIx, uint64_t Offset,
                           const MDNode *MDPtr, DebugLoc DL) const;

  virtual bool ReverseBranchCondition(
      SmallVectorImpl<MachineOperand> &Cond) const;

  virtual DFAPacketizer *CreateTargetScheduleState(
      const TargetMachine *TM, const ScheduleDAG *DAG) const;

  virtual bool isSchedulingBoundary(const MachineInstr *MI,
                                    const MachineBasicBlock *MBB,
                                    const MachineFunction &MF) const;
};

}
#endif
