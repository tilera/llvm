//===-- TileInstPrinter.cpp - Convert Tile MCInst to assembly syntax ------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This class prints an Tile MCInst to a .s file.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "asm-printer"
#include "TileInstPrinter.h"
#include "TileMCInst.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/Format.h"
#include "llvm/Support/Debug.h"
using namespace llvm;

#include "TileGenAsmWriter.inc"

void TileInstPrinter::printRegName(raw_ostream &OS, unsigned RegNo) const {
  OS << /* '$' << */ StringRef(getRegisterName(RegNo)).lower();
}

void TileInstPrinter::printInst(const MCInst *MI, raw_ostream &O,
                                StringRef Annot) {
  printInst((const TileMCInst *)(MI), O, Annot);
}

void TileInstPrinter::printInst(const TileMCInst *MI, raw_ostream &O,
                                StringRef Annot) {
  const char packetPadding = '\t', startPacket = '{', endPacket = '}';
  // Prefix the insn opening the packet.
  if (MI->isStartPacket())
    O << packetPadding << startPacket << '\n';

  printInstruction(MI, O);

  switch (MI->getIssueSlot()) {
  case TileII::ST_Solo:
    DEBUG(O << "\t# "
            << "SOLO");
    break;
  case TileII::ST_X0:
    DEBUG(O << "\t# "
            << "X0");
    break;
  case TileII::ST_X1:
    DEBUG(O << "\t# "
            << "X1");
    break;
  case TileII::ST_Y0:
    DEBUG(O << "\t# "
            << "Y0");
    break;
  case TileII::ST_Y1:
    DEBUG(O << "\t# "
            << "Y1");
    break;
  case TileII::ST_Y2:
    DEBUG(O << "\t# "
            << "Y2");
    break;
  case TileII::ST_None:
    DEBUG(O << "\t# "
            << "NONE");
    break;
  }

  // Suffix the insn closing the packet.
  if (MI->isEndPacket())
    O << '\n' << packetPadding << endPacket;

  printAnnotation(O, Annot);
}

static void printExpr(const MCExpr *Expr, raw_ostream &OS) {
  int Offset = 0;
  int Sub = 0;
  const MCSymbolRefExpr *SRE;
  const MCSymbolRefExpr *SUBE;

  if (const MCBinaryExpr *BE = dyn_cast<MCBinaryExpr>(Expr)) {
    SRE = dyn_cast<MCSymbolRefExpr>(BE->getLHS());
    if (BE->getOpcode() == MCBinaryExpr::Sub) {
      Sub = 1;
      SUBE = dyn_cast<MCSymbolRefExpr>(BE->getRHS());
    } else {
      const MCConstantExpr *CE = dyn_cast<MCConstantExpr>(BE->getRHS());
      assert(SRE && CE && "Binary expression must be sym+const.");
      Offset = CE->getValue();
    }
  } else if (!(SRE = dyn_cast<MCSymbolRefExpr>(Expr)))
    assert(false && "Unexpected MCExpr type.");

  MCSymbolRefExpr::VariantKind Kind = SRE->getKind();

  switch (Kind) {
  default:
    llvm_unreachable("Invalid kind!");
  case MCSymbolRefExpr::VK_None:
    break;
  case MCSymbolRefExpr::VK_Tile_PLT_CALL:
    OS << "plt(";
    break;
  case MCSymbolRefExpr::VK_Tile_HW0:
    OS << "hw0(";
    break;
  case MCSymbolRefExpr::VK_Tile_HW0_GOT:
    OS << "hw0_got(";
    break;
  case MCSymbolRefExpr::VK_Tile_HW0_LAST:
    OS << "hw0_last(";
    break;
  case MCSymbolRefExpr::VK_Tile_HW1:
    OS << "hw1(";
    break;
  case MCSymbolRefExpr::VK_Tile_HW1_LAST:
    OS << "hw1_last(";
    break;
  case MCSymbolRefExpr::VK_Tile_HW1_LAST_GOT:
    OS << "hw1_last_got(";
    break;
  case MCSymbolRefExpr::VK_Tile_HW2_LAST:
    OS << "hw2_last(";
    break;
  case MCSymbolRefExpr::VK_Tile_TLS_ADD:
    OS << "tls_add(";
    break;
  case MCSymbolRefExpr::VK_Tile_TLS_GD_ADD:
    OS << "tls_gd_add(";
    break;
  case MCSymbolRefExpr::VK_Tile_TLS_GD_CALL:
    OS << "tls_gd_call(";
    break;
  case MCSymbolRefExpr::VK_Tile_TLS_IE_LOAD:
    OS << "tls_ie_load(";
    break;
  case MCSymbolRefExpr::VK_Tile_HW0_TLS_GD:
    OS << "hw0_tls_gd(";
    break;
  case MCSymbolRefExpr::VK_Tile_HW0_TLS_IE:
    OS << "hw0_tls_ie(";
    break;
  case MCSymbolRefExpr::VK_Tile_HW0_TLS_LE:
    OS << "hw0_tls_le(";
    break;
  case MCSymbolRefExpr::VK_Tile_HW1_LAST_TLS_GD:
    OS << "hw1_last_tls_gd(";
    break;
  case MCSymbolRefExpr::VK_Tile_HW1_LAST_TLS_IE:
    OS << "hw1_last_tls_ie(";
    break;
  case MCSymbolRefExpr::VK_Tile_HW1_LAST_TLS_LE:
    OS << "hw1_last_tls_le(";
    break;
  }

  OS << SRE->getSymbol();

  if (Sub)
    OS << " - " << SUBE->getSymbol();

  if (Offset) {
    if (Offset > 0)
      OS << '+';
    OS << Offset;
  }

  if (Kind != MCSymbolRefExpr::VK_None)
    OS << ')';
}

void TileInstPrinter::printOperand(const MCInst *MI, unsigned OpNo,
                                   raw_ostream &O) {
  const MCOperand &Op = MI->getOperand(OpNo);
  if (Op.isReg()) {
    printRegName(O, Op.getReg());
    return;
  }

  if (Op.isImm()) {
    O << Op.getImm();
    return;
  }

  assert(Op.isExpr() && "unknown operand kind in printOperand");
  printExpr(Op.getExpr(), O);
}

void TileInstPrinter::printUnsignedImm(const MCInst *MI, int opNum,
                                       raw_ostream &O) {
  const MCOperand &MO = MI->getOperand(opNum);
  if (MO.isImm())
    O << (unsigned short int) MO.getImm();
  else
    printOperand(MI, opNum, O);
}

bool TileInstPrinter::printPICLNKReg(const MCInst *MI, unsigned opNum,
                                     raw_ostream &O) {

  const MCOperand &Op = MI->getOperand(opNum);
  const MCOperand &FName = MI->getOperand(opNum + 1);
  const MCSymbolRefExpr *SRE = dyn_cast<MCSymbolRefExpr>(FName.getExpr());

  assert(Op.isReg());

  O << SRE->getSymbol() << " = . + 8" << '\n';
  O << "\tlnk " << getRegisterName(Op.getReg());

  return true;
}

void TileInstPrinter::printS16ImmOperand(const MCInst *MI, unsigned OpNo,
                                         raw_ostream &O) {
  const MCOperand &Op = MI->getOperand(OpNo);
  if (Op.isImm())
    O << (short) Op.getImm();
  else if (Op.isFPImm())
    O << (short) Op.getFPImm();
  else if (Op.isExpr())
    printExpr(Op.getExpr(), O);
  else
    llvm_unreachable("only Imm && FPImm should enter here!\n");
}
