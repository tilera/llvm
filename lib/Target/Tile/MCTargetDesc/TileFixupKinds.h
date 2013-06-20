//===-- TileFixupKinds.h - Tile Specific Fixup Entries ----------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_TILE_TILEFIXUPKINDS_H
#define LLVM_TILE_TILEFIXUPKINDS_H

#include "llvm/MC/MCFixup.h"

namespace llvm {
namespace Tile {
// This table *must* be in the save order of
//
//   MCFixupKindInfo Infos[Tile::NumTargetFixupKinds]
//
// in TileAsmBackend.cpp.
enum Fixups {
  fixup_Tile_X0_HW0 = FirstTargetFixupKind,
  fixup_Tile_X1_HW0,

  fixup_Tile_X0_HW0_PCREL,
  fixup_Tile_X1_HW0_PCREL,

  fixup_Tile_X0_HW0_GOT,
  fixup_Tile_X1_HW0_GOT,

  fixup_Tile_X0_HW1,
  fixup_Tile_X1_HW1,

  fixup_Tile_X0_HW1_PCREL,
  fixup_Tile_X1_HW1_PCREL,

  fixup_Tile_X0_HW1_LAST,
  fixup_Tile_X1_HW1_LAST,

  fixup_Tile_X0_HW1_LAST_PCREL,
  fixup_Tile_X1_HW1_LAST_PCREL,

  fixup_Tile_X0_HW1_LAST_GOT,
  fixup_Tile_X1_HW1_LAST_GOT,

  fixup_Tile_X0_HW2_LAST,
  fixup_Tile_X1_HW2_LAST,

  fixup_Tile_X1_JUMPOFF,
  fixup_Tile_X1_JUMPOFF_PLT,

  fixup_Tile_X1_BROFF,
  // Marker
  LastTargetFixupKind,
  NumTargetFixupKinds = LastTargetFixupKind - FirstTargetFixupKind
};
} // namespace Tile
} // namespace llvm

#endif // LLVM_TILE_TILEFIXUPKINDS_H
