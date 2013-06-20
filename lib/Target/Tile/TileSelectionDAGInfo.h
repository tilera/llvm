//===-- TileSelectionDAGInfo.h - Tile SelectionDAG Info ---------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines the Tile subclass for TargetSelectionDAGInfo.
//
//===----------------------------------------------------------------------===//

#ifndef TILESELECTIONDAGINFO_H
#define TILESELECTIONDAGINFO_H

#include "llvm/Target/TargetSelectionDAGInfo.h"

namespace llvm {

class TileTargetMachine;

class TileSelectionDAGInfo : public TargetSelectionDAGInfo {
public:
  explicit TileSelectionDAGInfo(const TileTargetMachine &TM);
  ~TileSelectionDAGInfo();
};

}

#endif
