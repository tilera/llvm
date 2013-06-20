//===-- TileMCAsmInfo.h - Tile Asm Info ------------------------*- C++ -*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the declaration of the TileMCAsmInfo class.
//
//===----------------------------------------------------------------------===//

#ifndef TILETARGETASMINFO_H
#define TILETARGETASMINFO_H

#include "llvm/MC/MCAsmInfo.h"

namespace llvm {
class StringRef;
class Target;

class TileMCAsmInfo : public MCAsmInfo {
  virtual void anchor();
public:
  explicit TileMCAsmInfo(const Target &T, StringRef TT);
};

} // namespace llvm

#endif
