//===-- TileSubtarget.cpp - Tile Subtarget Information --------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the Tile specific subclass of TargetSubtargetInfo.
//
//===----------------------------------------------------------------------===//

#include "TileSubtarget.h"
#include "Tile.h"
#include "TileRegisterInfo.h"
#include "llvm/Support/TargetRegistry.h"

#define GET_SUBTARGETINFO_TARGET_DESC
#define GET_SUBTARGETINFO_CTOR
#include "TileGenSubtargetInfo.inc"

using namespace llvm;

void TileSubtarget::anchor() {}

TileSubtarget::TileSubtarget(const std::string &TT, const std::string &CPU,
                             const std::string &FS)
    : TileGenSubtargetInfo(TT, CPU, FS) {
  std::string CPUName = CPU;
  if (CPUName.empty())
    CPUName = "tilegx";

  // Parse features string.
  ParseSubtargetFeatures(CPUName, FS);

  // Initialize scheduling itinerary for the specified CPU.
  InstrItins = getInstrItineraryForCPU(CPUName);
}

bool TileSubtarget::enablePostRAScheduler(
    CodeGenOpt::Level OptLevel, TargetSubtargetInfo::AntiDepBreakMode &Mode,
    RegClassVector &CriticalPathRCs) const {
  Mode = TargetSubtargetInfo::ANTIDEP_NONE;
  CriticalPathRCs.clear();
  CriticalPathRCs.push_back(&Tile::CPURegsRegClass);
  return OptLevel >= CodeGenOpt::Aggressive;
}
