//===-- TileTargetInfo.cpp - Tile Target Implementation -------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "Tile.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/TargetRegistry.h"
using namespace llvm;

Target llvm::TheTileGXTarget;

extern "C" void LLVMInitializeTileTargetInfo() {
  RegisterTarget<Triple::tilegx, /*HasJIT=*/ true> X(TheTileGXTarget, "tilegx",
                                                     "TileGX 64bit");
}
