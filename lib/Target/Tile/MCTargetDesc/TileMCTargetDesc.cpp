//===-- TileMCTargetDesc.cpp - Tile Target Descriptions -------------------===//
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

#include "TileMCAsmInfo.h"
#include "TileMCTargetDesc.h"
#include "InstPrinter/TileInstPrinter.h"
#include "llvm/MC/MachineLocation.h"
#include "llvm/MC/MCCodeGenInfo.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/TargetRegistry.h"

#define GET_INSTRINFO_MC_DESC
#include "TileGenInstrInfo.inc"

#define GET_SUBTARGETINFO_MC_DESC
#include "TileGenSubtargetInfo.inc"

#define GET_REGINFO_MC_DESC
#include "TileGenRegisterInfo.inc"

using namespace llvm;

static MCInstrInfo *createTileGXMCInstrInfo() {
  MCInstrInfo *X = new MCInstrInfo();
  InitTileMCInstrInfo(X);
  return X;
}

static MCRegisterInfo *createTileGXMCRegisterInfo(StringRef TT) {
  MCRegisterInfo *X = new MCRegisterInfo();
  InitTileMCRegisterInfo(X, Tile::LR);
  return X;
}

static MCSubtargetInfo *
createTileGXMCSubtargetInfo(StringRef TT, StringRef CPU, StringRef FS) {
  MCSubtargetInfo *X = new MCSubtargetInfo();
  InitTileMCSubtargetInfo(X, TT, CPU, FS);
  return X;
}

static MCAsmInfo *createTileMCAsmInfo(const Target &T, StringRef TT) {
  MCAsmInfo *MAI = new TileMCAsmInfo(T, TT);

  MachineLocation Dst(MachineLocation::VirtualFP);
  MachineLocation Src(Tile::SP, 0);
  MAI->addInitialFrameState(0, Dst, Src);

  return MAI;
}

static MCCodeGenInfo *createTileMCCodeGenInfo(
    StringRef TT, Reloc::Model RM, CodeModel::Model CM, CodeGenOpt::Level OL) {
  MCCodeGenInfo *X = new MCCodeGenInfo();
  if (CM == CodeModel::JITDefault)
    RM = Reloc::Static;
  else if (RM == Reloc::Default)
    //RM = Reloc::PIC_;  --FIXME
    RM = Reloc::Static;
  X->InitMCCodeGenInfo(RM, CM, OL);
  return X;
}

static MCInstPrinter *createTileGXMCInstPrinter(
    const Target &T, unsigned SyntaxVariant, const MCAsmInfo &MAI,
    const MCInstrInfo &MII, const MCRegisterInfo &MRI,
    const MCSubtargetInfo &STI) {
  return new TileInstPrinter(MAI, MII, MRI);
}

static MCStreamer *
createMCStreamer(const Target &T, StringRef TT, MCContext &Ctx,
                 MCAsmBackend &MAB, raw_ostream &_OS, MCCodeEmitter *_Emitter,
                 bool RelaxAll, bool NoExecStack) {
  Triple TheTriple(TT);

  return createELFStreamer(Ctx, MAB, _OS, _Emitter, RelaxAll, NoExecStack);
}

extern "C" void LLVMInitializeTileTargetMC() {
  // Register the MC asm info.
  RegisterMCAsmInfoFn X(TheTileGXTarget, createTileMCAsmInfo);

  // Register the MC codegen info.
  TargetRegistry::RegisterMCCodeGenInfo(TheTileGXTarget,
                                        createTileMCCodeGenInfo);

  // Register the MC instruction info.
  TargetRegistry::RegisterMCInstrInfo(TheTileGXTarget, createTileGXMCInstrInfo);

  // Register the MC register info.
  TargetRegistry::RegisterMCRegInfo(TheTileGXTarget,
                                    createTileGXMCRegisterInfo);

  // Register the MC Code Emitter
  TargetRegistry::RegisterMCCodeEmitter(TheTileGXTarget,
                                        createTileGXMCCodeEmitter);

  // Register the object streamer.
  TargetRegistry::RegisterMCObjectStreamer(TheTileGXTarget, createMCStreamer);

  // Register the asm backend.
  TargetRegistry::RegisterMCAsmBackend(TheTileGXTarget, createTileGXAsmBackend);

  // Register the MC subtarget info.
  TargetRegistry::RegisterMCSubtargetInfo(TheTileGXTarget,
                                          createTileGXMCSubtargetInfo);

  // Register the MCInstPrinter.
  TargetRegistry::RegisterMCInstPrinter(TheTileGXTarget,
                                        createTileGXMCInstPrinter);
}
