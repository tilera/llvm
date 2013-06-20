//===-- TileSelectionDAGInfo.cpp - Tile SelectionDAG Info -----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the TileSelectionDAGInfo class.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "tile-selectiondag-info"
#include "TileTargetMachine.h"
using namespace llvm;

TileSelectionDAGInfo::TileSelectionDAGInfo(const TileTargetMachine &TM)
    : TargetSelectionDAGInfo(TM) {}

TileSelectionDAGInfo::~TileSelectionDAGInfo() {}
