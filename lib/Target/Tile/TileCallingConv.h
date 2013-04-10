//=== TileCallingConv.h - Tile Custom Calling Convention Routines -*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the custom routines for the Tile Calling Convention that
// aren't done by tablegen.
//
//===----------------------------------------------------------------------===//

#ifndef TILECALLINGCONV_H
#define TILECALLINGCONV_H

#include "llvm/IR/CallingConv.h"
#include "llvm/CodeGen/CallingConvLower.h"
#include "llvm/Target/TargetInstrInfo.h"

namespace llvm {

// For Tile, the stack frame have a special zone, the bottom
// 16bytes are reserved to keep incoming sp/lr, so both
// incoming and outgoing args on stack should be lifted by 16bytes.
static bool CC_Tile_StackArg(unsigned &ValNo, MVT &ValVT, MVT &LocVT,
                             CCValAssign::LocInfo &LocInfo,
                             ISD::ArgFlagsTy &ArgFlags, CCState &State) {

  if (LocVT == MVT::i32 || LocVT == MVT::f32) {
    unsigned Offset4 = State.AllocateStack(4, 8) + 16;
    State.addLoc(CCValAssign::getMem(ValNo, ValVT, Offset4, LocVT, LocInfo));
    return true;
  }

  if (LocVT == MVT::i64 || LocVT == MVT::f64) {
    unsigned Offset5 = State.AllocateStack(8, 8) + 16;
    State.addLoc(CCValAssign::getMem(ValNo, ValVT, Offset5, LocVT, LocInfo));
    return true;
  }

  return false;
}

} // End llvm namespace

#endif
