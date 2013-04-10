//===-- TileASMBackend.cpp - Tile Asm Backend  ----------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the TileAsmBackend class.
//
//===----------------------------------------------------------------------===//
//

#define DEBUG_TYPE "tileasmbackend"
#include "TileBaseInfo.h"
#include "TileFixupKinds.h"
#include "MCTargetDesc/TileMCTargetDesc.h"
#include "llvm/MC/MCAsmBackend.h"
#include "llvm/MC/MCAssembler.h"
#include "llvm/MC/MCDirectives.h"
#include "llvm/MC/MCELFObjectWriter.h"
#include "llvm/MC/MCFixupKindInfo.h"
#include "llvm/MC/MCObjectWriter.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/Debug.h"

using namespace llvm;

// Prepare value for the target space for it.
static uint64_t adjustFixupValue(const MCFixup &Fixup, uint64_t Value) {

  unsigned Kind = Fixup.getKind();
  switch (Kind) {
  default:
    return 0;
  case FK_Data_1:
  case FK_Data_2:
  case FK_Data_4:
  case FK_Data_8:
    break;
  case Tile::fixup_Tile_X1_JUMPOFF: {
    // inst{57-31} = Value >> 3
    uint64_t Adj_Value = Value >> 3;
    return (Adj_Value & 0x7FFFFFF) << 31;
  }
  case Tile::fixup_Tile_X1_BROFF: {
    // inst{36-31} = Value >> 3 {5-0}
    // inst{53-43} = Value >> 3 {16-6}
    uint64_t Adj_Value = Value >> 3;
    return ((Adj_Value & 0x3F) << 31) |
           (((Adj_Value & (0x7FF << 6)) >> 6) << 43);
  }
  }
  return Value;
}

namespace {
class TileAsmBackend : public MCAsmBackend {
  Triple::OSType OSType;

public:
  TileAsmBackend(const Target &T, Triple::OSType _OSType)
      : MCAsmBackend(), OSType(_OSType) {}

  MCObjectWriter *createObjectWriter(raw_ostream &OS) const {
    return createTileELFObjectWriter(OS, OSType);
  }

  // Apply the Value for given Fixup into the provided
  // data fragment, at the offset specified by the fixup.
  void applyFixup(const MCFixup &Fixup, char *Data, unsigned DataSize,
                  uint64_t Value) const {
    unsigned NumBytes = 8;
    Value = adjustFixupValue(Fixup, Value);
    if (!Value)
      return; // Doesn't change encoding.

    unsigned Offset = Fixup.getOffset();

    // For each byte of the fragment that the fixup touches,
    // mask in the bits from the fixup value. The Value has
    // been "split up" into the appropriate bitfields above.
    for (unsigned i = 0; i != NumBytes; ++i)
      Data[Offset + i] |= uint8_t((Value >> (i * 8)) & 0xff);
  }

  unsigned getNumFixupKinds() const { return Tile::NumTargetFixupKinds; }

  const MCFixupKindInfo &getFixupKindInfo(MCFixupKind Kind) const {
    const static MCFixupKindInfo Infos[Tile::NumTargetFixupKinds] = {
      // This table *must* be in same the order of fixup_* kinds in
      // TileFixupKinds.h.
      //
      // name, offset, bits, flags
      { "fixup_Tile_X0_HW0", 0, 16, 0 },
      { "fixup_Tile_X1_HW0", 0, 16, 0 },
      { "fixup_Tile_X0_HW0_PCREL", 0, 16, MCFixupKindInfo::FKF_IsPCRel },
      { "fixup_Tile_X1_HW0_PCREL", 0, 16, MCFixupKindInfo::FKF_IsPCRel },
      { "fixup_Tile_X0_HW0_GOT", 0, 16, 0 },
      { "fixup_Tile_X1_HW0_GOT", 0, 16, 0 },
      { "fixup_Tile_X0_HW1", 0, 16, 0 },
      { "fixup_Tile_X1_HW1", 0, 16, 0 },
      { "fixup_Tile_X0_HW1_PCREL", 0, 16, MCFixupKindInfo::FKF_IsPCRel },
      { "fixup_Tile_X1_HW1_PCREL", 0, 16, MCFixupKindInfo::FKF_IsPCRel },
      { "fixup_Tile_X0_HW1_LAST", 0, 16, 0 },
      { "fixup_Tile_X1_HW1_LAST", 0, 16, 0 },
      { "fixup_Tile_X0_HW1_LAST_PCREL", 0, 16, MCFixupKindInfo::FKF_IsPCRel },
      { "fixup_Tile_X1_HW1_LAST_PCREL", 0, 16, MCFixupKindInfo::FKF_IsPCRel },
      { "fixup_Tile_X0_HW1_LAST_GOT", 0, 16, MCFixupKindInfo::FKF_IsPCRel },
      { "fixup_Tile_X1_HW1_LAST_GOT", 0, 16, MCFixupKindInfo::FKF_IsPCRel },
      { "fixup_Tile_X0_HW2_LAST", 0, 16, 0 },
      { "fixup_Tile_X1_HW2_LAST", 0, 16, 0 },
      { "fixup_Tile_X1_JUMPOFF", 0, 27, MCFixupKindInfo::FKF_IsPCRel },
      { "fixup_Tile_X1_JUMPOFF_PLT", 0, 27, 0 },
      { "fixup_Tile_X1_BROFF", 0, 17, MCFixupKindInfo::FKF_IsPCRel },
    };

    if (Kind < FirstTargetFixupKind)
      return MCAsmBackend::getFixupKindInfo(Kind);

    assert(unsigned(Kind - FirstTargetFixupKind) < getNumFixupKinds() &&
           "Invalid kind!");
    return Infos[Kind - FirstTargetFixupKind];
  }

  // Check whether the given instruction may need relaxation.
  bool mayNeedRelaxation(const MCInst &Inst) const { return false; }

  // Target specific predicate for whether a given fixup
  // requires the associated instruction to be relaxed.
  bool fixupNeedsRelaxation(const MCFixup &Fixup, uint64_t Value,
                            const MCRelaxableFragment *DF,
                            const MCAsmLayout &Layout) const {
    // FIXME.
    assert(0 && "RelaxInstruction() unimplemented");
    return false;
  }

  /// Relax the instruction in the given fragment to the next wider instruction.
  void relaxInstruction(const MCInst &Inst, MCInst &Res) const {}

  // Write an (optimal) nop sequence of Count bytes to the given output.
  // If the target cannot generate such a sequence, it should return an error.
  bool writeNopData(uint64_t Count, MCObjectWriter *OW) const { return true; }
}; // class TileAsmBackend

} // namespace

// MCAsmBackend
MCAsmBackend *
llvm::createTileGXAsmBackend(const Target &T, StringRef TT, StringRef CPU) {
  return new TileAsmBackend(T, Triple(TT).getOS());
}
