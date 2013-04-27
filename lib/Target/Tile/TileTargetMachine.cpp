//===-- TileTargetMachine.cpp - Define TargetMachine for Tile -------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// Implements the info about Tile target spec.
//
//===----------------------------------------------------------------------===//

#include "TileTargetMachine.h"
#include "Tile.h"
#include "llvm/PassManager.h"
#include "llvm/CodeGen/Passes.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/TargetRegistry.h"
using namespace llvm;

static cl::opt<bool> DisableTileGXVLIWPacketizer(
    "disable-tilegx-packetizer", cl::Hidden, cl::ZeroOrMore, cl::init(false),
    cl::desc("Disable TileGX VLIW Packetizer"));

extern "C" void LLVMInitializeTileTarget() {
  // Register the target.
  RegisterTargetMachine<TileGXTargetMachine> B(TheTileGXTarget);
}

TileTargetMachine::TileTargetMachine(
    const Target &T, StringRef TT, StringRef CPU, StringRef FS,
    const TargetOptions &Options, Reloc::Model RM, CodeModel::Model CM,
    CodeGenOpt::Level OL)
    : LLVMTargetMachine(T, TT, CPU, FS, Options, RM, CM, OL),
      Subtarget(TT, CPU, FS), DL(Subtarget.getTargetDataLayout()),
      InstrItins(&Subtarget.getInstrItineraryData()), InstrInfo(*this),
      FrameLowering(Subtarget), TLInfo(*this), TSInfo(*this) {}

void TileGXTargetMachine::anchor() {}

TileGXTargetMachine::TileGXTargetMachine(
    const Target &T, StringRef TT, StringRef CPU, StringRef FS,
    const TargetOptions &Options, Reloc::Model RM, CodeModel::Model CM,
    CodeGenOpt::Level OL)
    : TileTargetMachine(T, TT, CPU, FS, Options, RM, CM, OL) {}

namespace {
// Tile Code Generator Pass Configuration Options.
class TilePassConfig : public TargetPassConfig {
public:
  TilePassConfig(TileTargetMachine *TM, PassManagerBase &PM)
      : TargetPassConfig(TM, PM) {}

  TileTargetMachine &getTileTargetMachine() const {
    return getTM<TileTargetMachine>();
  }

  const TileSubtarget &getTileSubtarget() const {
    return *getTileTargetMachine().getSubtargetImpl();
  }

  virtual bool addInstSelector();
  virtual bool addPreSched2();
  virtual bool addPreEmitPass();
};
} // namespace

TargetPassConfig *TileTargetMachine::createPassConfig(PassManagerBase &PM) {
  return new TilePassConfig(this, PM);
}

// Install an instruction selector pass using
// the ISelDag to gen Tile code.
bool TilePassConfig::addInstSelector() {
  addPass(createTileISelDag(getTileTargetMachine()));
  return false;
}

bool TilePassConfig::addPreSched2() {
  addPass(createTileExpandPseudoPass(getTileTargetMachine()));
  return true;
}

bool TilePassConfig::addPreEmitPass() {
  bool ShouldPrint = false;
  if (getOptLevel() != CodeGenOpt::None && !DisableTileGXVLIWPacketizer) {
    addPass(createTileVLIWPacketizer());
    ShouldPrint = true;
  }

  return ShouldPrint;
}

#if 0
void TileTargetMachine::addAnalysisPasses(PassManagerBase &PM) {
  // Add first the target-independent BasicTTI pass, then our Tile pass. This
  // allows the Tile pass to delegate to the target independent layer when
  // appropriate.
  PM.add(createBasicTargetTransformInfoPass(getTargetLowering()));
  PM.add(createTileTargetTransformInfoPass(this));
}
#endif
