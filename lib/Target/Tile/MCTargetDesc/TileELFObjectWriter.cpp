//===-- TileELFObjectWriter.cpp - Tile ELF Writer -------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "MCTargetDesc/TileBaseInfo.h"
#include "MCTargetDesc/TileFixupKinds.h"
#include "MCTargetDesc/TileMCTargetDesc.h"
#include "llvm/MC/MCAssembler.h"
#include "llvm/MC/MCELFObjectWriter.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCSection.h"
#include "llvm/MC/MCValue.h"
#include "llvm/Support/ErrorHandling.h"
#include <list>

using namespace llvm;

namespace {
class TileELFObjectWriter : public MCELFObjectTargetWriter {
public:
  TileELFObjectWriter(uint8_t OSABI);

  virtual ~TileELFObjectWriter();

  virtual unsigned GetRelocType(const MCValue &Target, const MCFixup &Fixup,
                                bool IsPCRel, bool IsRelocWithSymbol,
                                int64_t Addend) const;
  virtual unsigned getEFlags() const;
  virtual const MCSymbol *
  ExplicitRelSym(const MCAssembler &Asm, const MCValue &Target,
                 const MCFragment &F, const MCFixup &Fixup, bool IsPCRel) const;
};
}

// TileGX use RELA
TileELFObjectWriter::TileELFObjectWriter(uint8_t OSABI)
    : MCELFObjectTargetWriter(true, OSABI, ELF::EM_TILEGX,
                              /*HasRelocationAddend*/ true) {}

TileELFObjectWriter::~TileELFObjectWriter() {}

unsigned TileELFObjectWriter::getEFlags() const {

  //Just return 0 for TileGX.
  unsigned Flag = 0;

  return Flag;
}

const MCSymbol *TileELFObjectWriter::ExplicitRelSym(
    const MCAssembler &Asm, const MCValue &Target, const MCFragment &F,
    const MCFixup &Fixup, bool IsPCRel) const {
  assert(Target.getSymA() && "SymA cannot be 0.");
  const MCSymbol &Sym = Target.getSymA()->getSymbol().AliasedSymbol();

  if (Sym.getSection().getKind().isMergeableCString() ||
      Sym.getSection().getKind().isMergeableConst())
    return &Sym;

  return NULL;
}

unsigned TileELFObjectWriter::GetRelocType(
    const MCValue &Target, const MCFixup &Fixup, bool IsPCRel,
    bool IsRelocWithSymbol, int64_t Addend) const {
  // Determine the type of the relocation.
  unsigned Type = (unsigned) ELF::R_TILEGX_NONE;
  unsigned Kind = (unsigned) Fixup.getKind();

  switch (Kind) {
  default:
    llvm_unreachable("invalid fixup kind!");
  case FK_Data_1:
    Type = ELF::R_TILEGX_8;
    break;
  case FK_Data_2:
    Type = ELF::R_TILEGX_16;
    break;
  case FK_Data_4:
    Type = ELF::R_TILEGX_32;
    break;
  case FK_Data_8:
    Type = ELF::R_TILEGX_64;
    break;
  case Tile::fixup_Tile_X0_HW0:
    Type = ELF::R_TILEGX_IMM16_X0_HW0;
    break;
  case Tile::fixup_Tile_X1_HW0:
    Type = ELF::R_TILEGX_IMM16_X1_HW0;
    break;
  case Tile::fixup_Tile_X0_HW0_PCREL:
    Type = ELF::R_TILEGX_IMM16_X0_HW0_PCREL;
    break;
  case Tile::fixup_Tile_X1_HW0_PCREL:
    Type = ELF::R_TILEGX_IMM16_X1_HW0_PCREL;
    break;
  case Tile::fixup_Tile_X0_HW0_GOT:
    Type = ELF::R_TILEGX_IMM16_X0_HW0_GOT;
    break;
  case Tile::fixup_Tile_X1_HW0_GOT:
    Type = ELF::R_TILEGX_IMM16_X1_HW0_GOT;
    break;
  case Tile::fixup_Tile_X0_HW1:
    Type = ELF::R_TILEGX_IMM16_X0_HW1;
    break;
  case Tile::fixup_Tile_X1_HW1:
    Type = ELF::R_TILEGX_IMM16_X1_HW1;
    break;
  case Tile::fixup_Tile_X0_HW1_PCREL:
    Type = ELF::R_TILEGX_IMM16_X0_HW1_PCREL;
    break;
  case Tile::fixup_Tile_X1_HW1_PCREL:
    Type = ELF::R_TILEGX_IMM16_X1_HW1_PCREL;
    break;
  case Tile::fixup_Tile_X0_HW1_LAST:
    Type = ELF::R_TILEGX_IMM16_X0_HW1_LAST;
    break;
  case Tile::fixup_Tile_X1_HW1_LAST:
    Type = ELF::R_TILEGX_IMM16_X1_HW1_LAST;
    break;
  case Tile::fixup_Tile_X0_HW1_LAST_PCREL:
    Type = ELF::R_TILEGX_IMM16_X0_HW1_LAST_PCREL;
    break;
  case Tile::fixup_Tile_X1_HW1_LAST_PCREL:
    Type = ELF::R_TILEGX_IMM16_X1_HW1_LAST_PCREL;
    break;
  case Tile::fixup_Tile_X0_HW1_LAST_GOT:
    Type = ELF::R_TILEGX_IMM16_X0_HW1_LAST_GOT;
    break;
  case Tile::fixup_Tile_X1_HW1_LAST_GOT:
    Type = ELF::R_TILEGX_IMM16_X1_HW1_LAST_GOT;
    break;
  case Tile::fixup_Tile_X0_HW2_LAST:
    Type = ELF::R_TILEGX_IMM16_X0_HW2_LAST;
    break;
  case Tile::fixup_Tile_X1_HW2_LAST:
    Type = ELF::R_TILEGX_IMM16_X1_HW2_LAST;
    break;
  case Tile::fixup_Tile_X1_JUMPOFF:
    Type = ELF::R_TILEGX_JUMPOFF_X1;
    break;
  case Tile::fixup_Tile_X1_JUMPOFF_PLT:
    Type = ELF::R_TILEGX_JUMPOFF_X1_PLT;
    break;
  case Tile::fixup_Tile_X1_BROFF:
    Type = ELF::R_TILEGX_BROFF_X1;
    break;
  }

  return Type;
}

MCObjectWriter *
llvm::createTileELFObjectWriter(raw_ostream &OS, uint8_t OSABI) {
  MCELFObjectTargetWriter *MOTW = new TileELFObjectWriter(OSABI);
  return createELFObjectWriter(MOTW, OS, true);
}
