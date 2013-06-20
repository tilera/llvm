//===- TileMCInst.h - Tile sub-class of MCInst ----------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This class extends MCInst to allow some VLIW annotation.
//
//===----------------------------------------------------------------------===//

#ifndef TILEMCINST_H
#define TILEMCINST_H

#include "llvm/MC/MCInst.h"
#include "MCTargetDesc/TileBaseInfo.h"
#include "llvm/CodeGen/MachineInstr.h"

namespace llvm {
class TileMCInst : public MCInst {
  // Packet start and end markers.
  unsigned startPacket : 1, endPacket : 1;
  // The final slot this inst issued from. Inst encoding depends on this.
  unsigned issue_slot;
  const MachineInstr *MachineI;
public:
  explicit TileMCInst()
      : MCInst(), startPacket(0), endPacket(0), issue_slot(TileII::ST_None) {}

  const MachineInstr *getMI() const { return MachineI; }

  void setMI(const MachineInstr *MI) { MachineI = MI; }

  bool isStartPacket() const { return (startPacket); }
  bool isEndPacket() const { return (endPacket); }
  bool isSoloInst() const { return issue_slot == TileII::ST_Solo; }
  bool noIssueSlot() const { return issue_slot == TileII::ST_None; }

  void setStartPacket(bool yes) { startPacket = yes; }
  void setEndPacket(bool yes) { endPacket = yes; }
  void setIssueSlot(unsigned slot) { issue_slot = slot; }
  unsigned getIssueSlot() const { return issue_slot; }
};
}

#endif
