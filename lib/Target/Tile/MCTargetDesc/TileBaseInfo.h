//===-- TileBaseInfo.h - Top level definitions for TILE MC ------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains small standalone helper functions and enum definitions for
// the Tile target useful for the compiler back-end and the MC libraries.
//
//===----------------------------------------------------------------------===//
#ifndef TILEBASEINFO_H
#define TILEBASEINFO_H

#include "TileFixupKinds.h"
#include "TileMCTargetDesc.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/Support/DataTypes.h"
#include "llvm/Support/ErrorHandling.h"

namespace llvm {

// This namespace holds all of the target specific flags.
namespace TileII {
// Tile Specific MachineOperand flags.
enum TOF {

  MO_NO_FLAG,
  MO_NO_FLAG_PIC,

  /// plt(Symbol) relocation
  MO_PLT_CALL,

  MO_HW0,
  MO_HW0_GOT,
  MO_HW0_PIC,
  MO_HW0_LAST,
  MO_HW1,
  MO_HW1_LAST,
  MO_HW1_LAST_PIC,
  MO_HW1_LAST_GOT,
  MO_HW2_LAST,

  // TLS
  MO_TLS_ADD,
  MO_TLS_GD_ADD,
  MO_TLS_GD_CALL,
  MO_TLS_IE_LOAD,
  MO_HW0_TLS_GD,
  MO_HW0_TLS_IE,
  MO_HW0_TLS_LE,
  MO_HW1_LAST_TLS_GD,
  MO_HW1_LAST_TLS_IE,
  MO_HW1_LAST_TLS_LE
};

// Tile instruction encoding formats.
enum {
  FrmRRR = 0,

  FrmImm8 = 1,

  FrmMTImm14 = 2,

  FrmMFImm14 = 3,

  FrmImm16 = 4,

  FrmUnary = 5,

  FrmShift = 6,

  FrmBr = 7,

  FrmJmp = 8,

  FrmMM = 9,

  FrmLS = 10,

  FrmPseudo = 11
};

// Tile instruction issue type.
enum TileIssueType {
  IT_None = 0,
  IT_X0 = 1,
  IT_X1 = 2,
  IT_X0X1 = 3,
  IT_X0Y0 = 4,
  IT_X1Y1 = 5,
  IT_X1Y2 = 6,
  IT_X0X1Y0Y1 = 7,
  IT_Num = 8
};

enum {
  IssueTypePos = 0,
  IssueTypeMask = 0xF,

  SoloPos = 4,
  SoloMask = 0x1,

  FormatTypePos = 5,
  FormatTypeMask = 0xF
};

// Tile instruction issue slot.
// This describe the final slot inst issued to.
enum TileSlotType {
  ST_None = 0,
  ST_X0 = 1,
  ST_X1 = 2,
  ST_Y0 = 3,
  ST_Y1 = 4,
  ST_Y2 = 5,
  ST_Solo = 6
};
}

inline static std::pair<const MCSymbolRefExpr *, int64_t>
TileGetSymAndOffset(const MCFixup &Fixup) {
  MCFixupKind FixupKind = Fixup.getKind();

  if ((FixupKind < FirstTargetFixupKind) ||
      (FixupKind >= MCFixupKind(Tile::LastTargetFixupKind)))
    return std::make_pair((const MCSymbolRefExpr *)0, (int64_t) 0);

  const MCExpr *Expr = Fixup.getValue();
  MCExpr::ExprKind Kind = Expr->getKind();

  if (Kind == MCExpr::Binary) {
    const MCBinaryExpr *BE = static_cast<const MCBinaryExpr *>(Expr);
    const MCExpr *LHS = BE->getLHS();
    const MCConstantExpr *CE = dyn_cast<MCConstantExpr>(BE->getRHS());

    if ((LHS->getKind() != MCExpr::SymbolRef) || !CE)
      return std::make_pair((const MCSymbolRefExpr *)0, (int64_t) 0);

    return std::make_pair(cast<MCSymbolRefExpr>(LHS), CE->getValue());
  }

  if (Kind != MCExpr::SymbolRef)
    return std::make_pair((const MCSymbolRefExpr *)0, (int64_t) 0);

  return std::make_pair(cast<MCSymbolRefExpr>(Expr), 0);
}
}

#endif
