//===-- TileMachineFunctionInfo.cpp - Private data used for Tile ----------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "TileMachineFunction.h"
#include "TileInstrInfo.h"
#include "TileSubtarget.h"
#include "MCTargetDesc/TileBaseInfo.h"
#include "llvm/IR/Function.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/Support/CommandLine.h"

using namespace llvm;

static cl::opt<bool>
FixGlobalBaseReg("tile-fix-global-base-reg", cl::Hidden, cl::init(true),
                 cl::desc("Always use $51 as the global base register."));
static cl::opt<bool>
FixLinkReg("tile-fix-link-reg", cl::Hidden, cl::init(true),
           cl::desc("Always use $50 as the link register."));

bool TileFunctionInfo::globalBaseRegFixed() const { return FixGlobalBaseReg; }

bool TileFunctionInfo::globalBaseRegSet() const { return GlobalBaseReg; }

unsigned TileFunctionInfo::getGlobalBaseReg() {
  // Return if it has already been initialized.
  if (GlobalBaseReg)
    return GlobalBaseReg;

  if (FixGlobalBaseReg)
    return GlobalBaseReg = Tile::R51;

  const TargetRegisterClass *RC = &Tile::CPURegsRegClass;

  return GlobalBaseReg = MF.getRegInfo().createVirtualRegister(RC);
}

bool TileFunctionInfo::linkRegFixed() const { return FixLinkReg; }

bool TileFunctionInfo::linkRegSet() const { return LinkReg; }

unsigned TileFunctionInfo::getLinkReg() {
  // Return if it has already been initialized.
  if (LinkReg)
    return LinkReg;

  if (FixLinkReg)
    return LinkReg = Tile::R50;

  const TargetRegisterClass *RC = &Tile::CPURegsRegClass;

  return LinkReg = MF.getRegInfo().createVirtualRegister(RC);
}

void TileFunctionInfo::anchor() {}
