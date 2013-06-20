//===-- Tile.h - Top-level interface for Tile representation ----*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the entry points for global functions defined in
// the LLVM Tile back-end.
//
//===----------------------------------------------------------------------===//

#ifndef TARGET_TILE_H
#define TARGET_TILE_H

#include "MCTargetDesc/TileMCTargetDesc.h"
#include "llvm/Target/TargetMachine.h"

namespace llvm {
class TileTargetMachine;
class FunctionPass;
class MachineInstr;
class AsmPrinter;
class MCInst;

FunctionPass *createTileISelDag(TileTargetMachine &TM);
FunctionPass *createTileDelaySlotFillerPass(TileTargetMachine &TM);
FunctionPass *createTileExpandPseudoPass(TileTargetMachine &TM);
FunctionPass *createTileEmitGPRestorePass(TileTargetMachine &TM);
FunctionPass *createTileVLIWPacketizer();
void LowerTileMachineInstrToMCInst(const MachineInstr *MI, MCInst &OutMI,
                                   AsmPrinter &AP);

/// \brief Creates an Tile-specific Target Transformation Info pass.
ImmutablePass *createTileTargetTransformInfoPass(const TileTargetMachine *TM);
} // end namespace llvm

// TILE-Gx use 10 registers, r0 ~ r9 for arg passing.
#define TILEGX_AREG_NUM 10
// TILE-Gx reserve the bottom 16bytes on frame for special usage.
#define TILEGX_BZONE_SIZE 16

#endif
