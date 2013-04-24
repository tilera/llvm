//===-- TileTargetMachine.h - Define TargetMachine for Tile -----*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file declares the Tile specific subclass of TargetMachine.
//
//===----------------------------------------------------------------------===//

#ifndef TILETARGETMACHINE_H
#define TILETARGETMACHINE_H

#include "TileFrameLowering.h"
#include "TileInstrInfo.h"
#include "TileISelLowering.h"
#include "TileSelectionDAGInfo.h"
#include "TileSubtarget.h"
#include "TileMachineFunction.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineJumpTableInfo.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetFrameLowering.h"

namespace llvm {
class formatted_raw_ostream;

class TileTargetMachine : public LLVMTargetMachine {
  TileSubtarget Subtarget;
  const DataLayout DL;
  const InstrItineraryData *InstrItins;
  TileInstrInfo InstrInfo;
  TileFrameLowering FrameLowering;
  TileTargetLowering TLInfo;
  TileSelectionDAGInfo TSInfo;

public:
  TileTargetMachine(const Target &T, StringRef TT, StringRef CPU, StringRef FS,
                    const TargetOptions &Options, Reloc::Model RM,
                    CodeModel::Model CM, CodeGenOpt::Level OL);

  virtual const TileInstrInfo *getInstrInfo() const { return &InstrInfo; }
  virtual const TargetFrameLowering *getFrameLowering() const {
    return &FrameLowering;
  }
  virtual const TileSubtarget *getSubtargetImpl() const { return &Subtarget; }
  virtual const DataLayout *getDataLayout() const { return &DL; }

  virtual const InstrItineraryData *getInstrItineraryData() const {
    return InstrItins;
  }

  virtual const TileRegisterInfo *getRegisterInfo() const {
    return &InstrInfo.getRegisterInfo();
  }

  virtual const TileTargetLowering *getTargetLowering() const {
    return &TLInfo;
  }

  virtual const TileSelectionDAGInfo *getSelectionDAGInfo() const {
    return &TSInfo;
  }

  // Pass Pipeline Configuration.
  virtual TargetPassConfig *createPassConfig(PassManagerBase &PM);

  /// \brief Register Tile analysis passes with a pass manager.
  virtual void addAnalysisPasses(PassManagerBase &PM);
};

class TileGXTargetMachine : public TileTargetMachine {
  virtual void anchor();
public:
  TileGXTargetMachine(const Target &T, StringRef TT, StringRef CPU,
                      StringRef FS, const TargetOptions &Options,
                      Reloc::Model RM, CodeModel::Model CM,
                      CodeGenOpt::Level OL);
};
} // End llvm namespace

#endif
