//===-- TileMCTargetDesc.h - Tile Target Descriptions -----------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file provides Tile specific target descriptions.
//
//===----------------------------------------------------------------------===//

#ifndef TILEMCTARGETDESC_H
#define TILEMCTARGETDESC_H

#include "llvm/Support/DataTypes.h"

namespace llvm {
class MCAsmBackend;
class MCCodeEmitter;
class MCContext;
class MCInstrInfo;
class MCObjectWriter;
class MCRegisterInfo;
class MCSubtargetInfo;
class StringRef;
class Target;
class raw_ostream;

extern Target TheTileGXTarget;

MCCodeEmitter *
createTileGXMCCodeEmitter(const MCInstrInfo &MCII, const MCRegisterInfo &MRI,
                          const MCSubtargetInfo &STI, MCContext &Ctx);

MCAsmBackend *
createTileGXAsmBackend(const Target &T, StringRef TT, StringRef CPU);

MCObjectWriter *createTileELFObjectWriter(raw_ostream &OS, uint8_t OSABI);
} // End llvm namespace

// Defines symbolic names for Tile registers.  This defines a mapping from
// register name to register number.
#define GET_REGINFO_ENUM
#include "TileGenRegisterInfo.inc"

// Defines symbolic names for the Tile instructions.
#define GET_INSTRINFO_ENUM
#include "TileGenInstrInfo.inc"

#define GET_SUBTARGETINFO_ENUM
#include "TileGenSubtargetInfo.inc"

#endif
