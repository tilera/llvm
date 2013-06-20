//===-- TileMCCodeEmitter.cpp - Convert Tile Code to Machine Code ---------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the TileMCCodeEmitter class.
//
//===----------------------------------------------------------------------===//
//
#define DEBUG_TYPE "mccodeemitter"
#include "TileMCInst.h"
#include "MCTargetDesc/TileBaseInfo.h"
#include "MCTargetDesc/TileFixupKinds.h"
#include "MCTargetDesc/TileMCTargetDesc.h"
#include "llvm/ADT/APFloat.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/MC/MCCodeEmitter.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/Format.h"
#include "llvm/Support/Debug.h"

using namespace llvm;

namespace {
class TileMCCodeEmitter : public MCCodeEmitter {
  TileMCCodeEmitter(const TileMCCodeEmitter &); // DO NOT IMPLEMENT
  void operator=(const TileMCCodeEmitter &);    // DO NOT IMPLEMENT
  const MCInstrInfo &MCII;
  const MCSubtargetInfo &STI;
  MCContext &Ctx;
  bool IsLittleEndian;

public:
  TileMCCodeEmitter(const MCInstrInfo &mcii, const MCSubtargetInfo &sti,
                    MCContext &ctx, bool IsLittle)
      : MCII(mcii), STI(sti), Ctx(ctx), IsLittleEndian(IsLittle) {}

  ~TileMCCodeEmitter() {}

  void EmitByte(unsigned char C, raw_ostream &OS) const { OS << (char) C; }

  void EmitInstruction(uint64_t Val, unsigned Size, raw_ostream &OS) const {
    // Output the instruction encoding in little endian byte order.
    for (unsigned i = 0; i < Size; ++i) {
      unsigned Shift = IsLittleEndian ? i * 8 : (Size - 1 - i) * 8;
      EmitByte((Val >> Shift) & 0xff, OS);
    }
  }

  void EncodeInstruction(const MCInst &MI, raw_ostream &OS,
                         SmallVectorImpl<MCFixup> &Fixups) const;

  // TableGen'erated function for getting the binary encoding for
  // an instruction.
  uint64_t getBinaryCodeForInstr(const MCInst &MI,
                                 SmallVectorImpl<MCFixup> &Fixups) const;

  // Return binary encoding of the jump target operand.
  // If the machine operand requires relocation, record
  // the relocation and return zero.
  unsigned getJumpTargetOpValue(const MCInst &MI, unsigned OpNo,
                                SmallVectorImpl<MCFixup> &Fixups) const;

  // Return binary encoding of the branch target operand.
  // If the machine operand requires relocation, record
  // the relocation and return zero.
  unsigned getBranchTargetOpValue(const MCInst &MI, unsigned OpNo,
                                  SmallVectorImpl<MCFixup> &Fixups) const;

  // Return binary encoding of operand. If the machin operand
  // requires relocation, record the relocation and return zero.
  unsigned getMachineOpValue(const MCInst &MI, const MCOperand &MO,
                             SmallVectorImpl<MCFixup> &Fixups) const;
}; // class TileMCCodeEmitter
}  // namespace

MCCodeEmitter *llvm::createTileGXMCCodeEmitter(
    const MCInstrInfo &MCII, const MCRegisterInfo &MRI,
    const MCSubtargetInfo &STI, MCContext &Ctx) {
  return new TileMCCodeEmitter(MCII, STI, Ctx, true);
}

/// Emit the instruction.
void TileMCCodeEmitter::EncodeInstruction(
    const MCInst &MI, raw_ostream &OS, SmallVectorImpl<MCFixup> &Fixups) const {
  static uint64_t InstBundleBit = 0x0;
  static uint64_t FNOP_Y0 = (0x6LL << 27) | (0x3LL << 18) | (0x3LL << 12);
  static uint64_t FNOP_Y1 = (0x7LL << 58) | (0x3LL << 49) | (0x8LL << 43);
  static bool IsBundling = false;
  static unsigned InstBundleSize = 0;
  static unsigned InstBundledType[3] = { 0 };
  const TileMCInst &TileMI = (const TileMCInst &)MI;
  uint64_t Binary = getBinaryCodeForInstr(MI, Fixups);
  const MCInstrDesc &Desc = MCII.get(MI.getOpcode());
  uint64_t TSFlags =
      (Desc.TSFlags >> TileII::FormatTypePos) & TileII::FormatTypeMask;

  assert((TSFlags != TileII::FrmPseudo) &&
         "Pseudo opcode found in EncodeInstruction()");

  assert(!TileMI.noIssueSlot() && "no issue slot for this inst!");

  if (TileMI.isSoloInst()) {
    assert(!IsBundling && "found Solo inst inner a instruction bundle");
    EmitInstruction(Binary, 8, OS);
    return;
  }

  if (TileMI.isStartPacket()) {
    assert(!IsBundling && "nested Start Packet found!");

    IsBundling = true;

    assert(!(InstBundleBit & Binary) && "inst bundle bit overlapped!");

    InstBundleBit |= Binary;
    InstBundledType[InstBundleSize] = TileMI.getIssueSlot();
    InstBundleSize++;
  } else if (TileMI.isEndPacket()) {
    assert(IsBundling && "no Start Packet match this End Packet");

    IsBundling = false;

    assert(!(InstBundleBit & Binary) && "inst bundle bit overlapped!");

    InstBundleBit |= Binary;
    InstBundledType[InstBundleSize] = TileMI.getIssueSlot();
    InstBundleSize++;

    if ((InstBundleBit & 0xC000000000000000LL) != 0 && (InstBundleSize != 3)) {
      // Y mode:
      // we need to fill fnop into the empty slot.
      if (InstBundledType[0] != TileII::ST_Y0 &&
          InstBundledType[1] != TileII::ST_Y0)
        InstBundleBit = InstBundleBit | FNOP_Y0;
      else
        InstBundleBit = InstBundleBit | FNOP_Y1;
    }

    EmitInstruction(InstBundleBit, 8, OS);

    // clear status
    InstBundleBit = 0x0;
    InstBundleSize = 0;
    InstBundledType[0] = 0;
    InstBundledType[1] = 0;
    InstBundledType[2] = 0;
  } else {
    assert(!(InstBundleBit & Binary) && "inst bundle bit overlapped!");

    InstBundleBit |= Binary;
    InstBundledType[InstBundleSize] = TileMI.getIssueSlot();
    InstBundleSize++;
  }
}

unsigned TileMCCodeEmitter::getBranchTargetOpValue(
    const MCInst &MI, unsigned OpNo, SmallVectorImpl<MCFixup> &Fixups) const {

  const MCOperand &MO = MI.getOperand(OpNo);
  assert(MO.isExpr() && "getBranchTargetOpValue expects only expressions");

  const MCExpr *Expr = MO.getExpr();
  Fixups.push_back(
      MCFixup::Create(0, Expr, MCFixupKind(Tile::fixup_Tile_X1_BROFF)));
  return 0;
}

unsigned TileMCCodeEmitter::getJumpTargetOpValue(
    const MCInst &MI, unsigned OpNo, SmallVectorImpl<MCFixup> &Fixups) const {

  const MCOperand &MO = MI.getOperand(OpNo);
  assert(MO.isExpr() && "getJumpTargetOpValue expects only expressions");

  const MCExpr *Expr = MO.getExpr();
  const MCSymbolRefExpr *SymExpr = cast<MCSymbolRefExpr>(Expr);
  Tile::Fixups FixupKind;

  if (SymExpr->getKind() == MCSymbolRefExpr::VK_Tile_PLT_CALL)
    FixupKind = Tile::fixup_Tile_X1_JUMPOFF_PLT;
  else if (SymExpr->getKind() == MCSymbolRefExpr::VK_None)
    FixupKind = Tile::fixup_Tile_X1_JUMPOFF;
  Fixups.push_back(MCFixup::Create(0, Expr, MCFixupKind(FixupKind)));
  return 0;
}

unsigned TileMCCodeEmitter::getMachineOpValue(
    const MCInst &MI, const MCOperand &MO,
    SmallVectorImpl<MCFixup> &Fixups) const {
  // FIXME:
  //   no consideration for Y mode relocation yet.
  const unsigned IssueSlot = ((const TileMCInst &)MI).getIssueSlot();
  const unsigned RelocBias =
      (IssueSlot == TileII::ST_Solo) ? 1 : IssueSlot - 1;

  if (MO.isReg()) {
    return Ctx.getRegisterInfo().getEncodingValue(MO.getReg());
  } else if (MO.isImm()) {
    return static_cast<unsigned>(MO.getImm());
  } else if (MO.isFPImm()) {
    return static_cast<unsigned>(APFloat(
        MO.getFPImm()).bitcastToAPInt().getHiBits(32).getLimitedValue());
  }

  // MO must be an Expr.
  assert(MO.isExpr());

  bool IsPCRel = false;
  const MCExpr *Expr = MO.getExpr();
  const MCExpr *ExprLHS = Expr;
  const MCExpr *ExprRHS = NULL;
  MCExpr::ExprKind Kind = Expr->getKind();

  DEBUG(dbgs() << "Expr-Kind: " << Kind
               << ", MCExpr::Binary: " << MCExpr::Binary << "\n");

  if (Kind == MCExpr::Binary) {
    ExprLHS = static_cast<const MCBinaryExpr *>(Expr)->getLHS();
    Kind = ExprLHS->getKind();
    ExprRHS = static_cast<const MCBinaryExpr *>(Expr)->getRHS();
    if ((cast<MCSymbolRefExpr>(ExprRHS))->getSymbol().isTemporary())
      IsPCRel = true;
  }

  assert(Kind == MCExpr::SymbolRef);

  Tile::Fixups FixupKind;

  DEBUG(dbgs() << "MCSymbol-Kind: " << cast<MCSymbolRefExpr>(ExprLHS)->getKind()
               << ", VK_Tile_HW2_LAST: " << MCSymbolRefExpr::VK_Tile_HW2_LAST
               << "\n");

  switch (cast<MCSymbolRefExpr>(ExprLHS)->getKind()) {
  case MCSymbolRefExpr::VK_Tile_HW0:
    FixupKind = (Tile::Fixups)(Tile::fixup_Tile_X0_HW0 + RelocBias);
    break;
  case MCSymbolRefExpr::VK_Tile_HW0_GOT:
    FixupKind = (Tile::Fixups)(Tile::fixup_Tile_X0_HW0_GOT + RelocBias);
    break;
  case MCSymbolRefExpr::VK_Tile_HW1:
    FixupKind = (Tile::Fixups)(Tile::fixup_Tile_X0_HW1 + RelocBias);
    break;
  case MCSymbolRefExpr::VK_Tile_HW1_LAST:
    FixupKind = (Tile::Fixups)(Tile::fixup_Tile_X0_HW1_LAST + RelocBias);
    break;
  case MCSymbolRefExpr::VK_Tile_HW1_LAST_GOT:
    FixupKind = (Tile::Fixups)(Tile::fixup_Tile_X0_HW1_LAST_GOT + RelocBias);
    break;
  case MCSymbolRefExpr::VK_Tile_HW2_LAST:
    FixupKind = (Tile::Fixups)(Tile::fixup_Tile_X0_HW2_LAST + RelocBias);
    break;
  default:
    llvm_unreachable("no fixup found!\n");
    break;
  } // switch

  if (IsPCRel)
    FixupKind = (Tile::Fixups)((unsigned) FixupKind + 1);

  Fixups.push_back(MCFixup::Create(0, MO.getExpr(), MCFixupKind(FixupKind)));

  // All of the information is in the fixup.
  return 0;
}

#include "TileGenMCCodeEmitter.inc"
