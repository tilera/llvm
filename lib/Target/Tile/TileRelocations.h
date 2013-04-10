//===-- TileRelocations.h - Tile Code Relocations ---------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines the Tile target-specific relocation types
// (for relocation-model=static).
//
//===----------------------------------------------------------------------===//

#ifndef TILERELOCATIONS_H_
#define TILERELOCATIONS_H_

#include "llvm/CodeGen/MachineRelocation.h"

namespace llvm {
namespace Tile {
enum RelocationType {
  // TBD: we will enlarge this enum when
  // support old JIT.
  reloc_tile_none = 1
};
}
}

#endif /* TILERELOCATIONS_H_ */
