//===-- TileMCInstLower.cpp - Convert Tile MachineInstr to MCInst ---------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains code to lower Tile MachineInstrs to their corresponding
// MCInst records.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "tile-mcinst-lower"
#include "Tile.h"
#include "TileMCInst.h"
#include "TileMCInstLower.h"
#include "TileAsmPrinter.h"
#include "TileInstrInfo.h"
#include "MCTargetDesc/TileBaseInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/CodeGen/MachineOperand.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/Target/Mangler.h"

using namespace llvm;

static MCOperand GetSymbolRef(const MachineOperand &MO, const MCSymbol *Symbol,
                              AsmPrinter &Printer) {
  MCContext &Ctx = Printer.OutContext;
  MCSymbolRefExpr::VariantKind Kind;

  switch (MO.getTargetFlags()) {
  default:
    llvm_unreachable("Invalid target flag!");
  case TileII::MO_NO_FLAG:
    Kind = MCSymbolRefExpr::VK_None;
    break;
  case TileII::MO_NO_FLAG_PIC:
    Kind = MCSymbolRefExpr::VK_None;
    break;
  case TileII::MO_PLT_CALL:
    Kind = MCSymbolRefExpr::VK_Tile_PLT_CALL;
    break;
  case TileII::MO_HW0:
  case TileII::MO_HW0_PIC:
    Kind = MCSymbolRefExpr::VK_Tile_HW0;
    break;
  case TileII::MO_HW0_GOT:
    Kind = MCSymbolRefExpr::VK_Tile_HW0_GOT;
    break;
  case TileII::MO_HW0_LAST:
    Kind = MCSymbolRefExpr::VK_Tile_HW0_LAST;
    break;
  case TileII::MO_HW1:
    Kind = MCSymbolRefExpr::VK_Tile_HW1;
    break;
  case TileII::MO_HW1_LAST:
  case TileII::MO_HW1_LAST_PIC:
    Kind = MCSymbolRefExpr::VK_Tile_HW1_LAST;
    break;
  case TileII::MO_HW1_LAST_GOT:
    Kind = MCSymbolRefExpr::VK_Tile_HW1_LAST_GOT;
    break;
  case TileII::MO_HW2_LAST:
    Kind = MCSymbolRefExpr::VK_Tile_HW2_LAST;
    break;
  case TileII::MO_TLS_ADD:
    Kind = MCSymbolRefExpr::VK_Tile_TLS_ADD;
    break;
  case TileII::MO_TLS_GD_ADD:
    Kind = MCSymbolRefExpr::VK_Tile_TLS_GD_ADD;
    break;
  case TileII::MO_TLS_GD_CALL:
    Kind = MCSymbolRefExpr::VK_Tile_TLS_GD_CALL;
    break;
  case TileII::MO_TLS_IE_LOAD:
    Kind = MCSymbolRefExpr::VK_Tile_TLS_IE_LOAD;
    break;
  case TileII::MO_HW0_TLS_GD:
    Kind = MCSymbolRefExpr::VK_Tile_HW0_TLS_GD;
    break;
  case TileII::MO_HW0_TLS_IE:
    Kind = MCSymbolRefExpr::VK_Tile_HW0_TLS_IE;
    break;
  case TileII::MO_HW0_TLS_LE:
    Kind = MCSymbolRefExpr::VK_Tile_HW0_TLS_LE;
    break;
  case TileII::MO_HW1_LAST_TLS_GD:
    Kind = MCSymbolRefExpr::VK_Tile_HW1_LAST_TLS_GD;
    break;
  case TileII::MO_HW1_LAST_TLS_IE:
    Kind = MCSymbolRefExpr::VK_Tile_HW1_LAST_TLS_IE;
    break;
  case TileII::MO_HW1_LAST_TLS_LE:
    Kind = MCSymbolRefExpr::VK_Tile_HW1_LAST_TLS_LE;
    break;
  }

  const MCExpr *Expr = NULL;
  if (MO.getTargetFlags() == TileII::MO_NO_FLAG_PIC) {
    const MachineFunction *MF = MO.getParent()->getParent()->getParent();
    Expr = MCSymbolRefExpr::Create(MF->getPICBaseSymbol(), Kind, Ctx);
  } else
    Expr = MCSymbolRefExpr::Create(Symbol, Kind, Ctx);

  if (!MO.isJTI() && MO.getOffset())
    Expr = MCBinaryExpr::CreateAdd(
        Expr, MCConstantExpr::Create(MO.getOffset(), Ctx), Ctx);

  // Subtract off the PIC base if required.
  if (MO.getTargetFlags() == TileII::MO_HW0_PIC ||
      MO.getTargetFlags() == TileII::MO_HW1_LAST_PIC) {
    const MachineFunction *MF = MO.getParent()->getParent()->getParent();
    const MCExpr *PB = MCSymbolRefExpr::Create(MF->getPICBaseSymbol(), Ctx);
    Expr = MCBinaryExpr::CreateSub(Expr, PB, Ctx);
  }

  return MCOperand::CreateExpr(Expr);
}

static unsigned
mapToOpcodeWithIssueSlot(unsigned Op, const unsigned IssueSlot,
                         const TileII::TileIssueType IssueType) {

  // Adjust some pseudo opcode to their actual opcode
  switch (Op) {
  case Tile::BEQZ32:
  case Tile::BGEZ32:
  case Tile::BLEZ32:
  case Tile::BLTZ32:
  case Tile::BNEZ32:
  case Tile::BFINS32:
  case Tile::BFEXTU32:
  case Tile::FSINGLE_PACK232_64:
    Op = Op - 2;
    break;
  case Tile::ST132:
  case Tile::ST232:
  case Tile::ST432:
  case Tile::ORI32:
  case Tile::CLZ32:
  case Tile::CTZ32:
  case Tile::XORI32:
  case Tile::LD1S32:
  case Tile::LD1U32:
  case Tile::LD2S32:
  case Tile::LD2U32:
  case Tile::LD4S32:
  case Tile::MOVELI32:
  case Tile::V4INT_L32:
  case Tile::CMOVNEZ32:
  case Tile::LD0_Z64_F:
  case Tile::ST0_Z64_F:
  case Tile::SHLXI32_64:
  case Tile::BFEXTU32_64:
  case Tile::CMPLTUI32_64:
  case Tile::SHL16INSLI32:
  case Tile::FSINGLE_PACK164:
  case Tile::MUL_LS_LS32:
  case Tile::MUL_LU_LU32:
    Op = Op - 3;
    break;
  case Tile::ST432_F:
  case Tile::LD4S32_F:
  case Tile::LD0_Z64_V16:
  case Tile::ST0_Z64_V16:
  case Tile::BFEXTU64_32:
  case Tile::CMOVNEZ64_32:
    Op = Op - 4;
    break;
  case Tile::OR32:
  case Tile::ST464:
  case Tile::XOR32:
  case Tile::AND32:
  case Tile::NOR32:
  case Tile::ANDI32:
  case Tile::SHRS32:
  case Tile::ROTL32:
  case Tile::ROTLI32:
  case Tile::MOVEI32:
  case Tile::SHRSI32:
  case Tile::CMPEQ32:
  case Tile::CMPNE32:
  case Tile::CMPLTU32:
  case Tile::CMPLEU32:
  case Tile::SHLI64_32:
  case Tile::SHRU64_32:
  case Tile::CMOVNEZC32:
  case Tile::SHRUI32_64:
  case Tile::CMPEQI32_64:
  case Tile::CMPLTS32_64:
  case Tile::CMPLES32_64:
  case Tile::CMPLTSI32_64:
  case Tile::LD0_Z64_V32:
  case Tile::ST0_Z64_V32:
    Op = Op - 5;
    break;
  case Tile::SHRS64_32:
  case Tile::SHRSI32_64:
  case Tile::CMOVNEZF32:
  case Tile::CMPEQ32_64:
  case Tile::CMPNE32_64:
  case Tile::CMPLTU32_64:
  case Tile::CMPLEU32_64:
  case Tile::LD0_Z64_V8:
  case Tile::ST0_Z64_V8:
  case Tile::SHRUI64_32:
    Op = Op - 6;
    break;
  case Tile::CMOVNEZF32_32:
  case Tile::SHRSI64_32:
    Op = Op - 7;
    break;
  case Tile::CMOVNEZF64:
    Op = Op - 8;
    break;
  // Alphabetic overlapped with SHL16INSLI
  case Tile::SHL64_32:
  case Tile::CMOVNEZF64_32:
    Op = Op - 9;
    break;
  default:
    break;
  }

  switch (IssueType) {
  case TileII::IT_X0:
    assert(IssueSlot == TileII::ST_X0 && "mismatch IssueSlot and IssueType!");
    return Op + 1;
  case TileII::IT_X1:
    assert(IssueSlot == TileII::ST_X1 && "mismatch IssueSlot and IssueType!");
    return Op + 1;
  case TileII::IT_X0X1:
    assert((IssueSlot == TileII::ST_X0 || IssueSlot == TileII::ST_X1) &&
           "mismatch IssueSlot and IssueType!");
    return Op + IssueSlot;
  case TileII::IT_X0Y0:
    if (IssueSlot == TileII::ST_X0)
      return Op + 1;
    else if (IssueSlot == TileII::ST_Y0)
      return Op + 2;
    else
      llvm_unreachable("mismatch IssueSlot and IssueType!");
  case TileII::IT_X1Y1:
    if (IssueSlot == TileII::ST_X1)
      return Op + 1;
    else if (IssueSlot == TileII::ST_Y1)
      return Op + 2;
    else
      llvm_unreachable("mismatch IssueSlot and IssueType!");
  case TileII::IT_X1Y2:
    if (IssueSlot == TileII::ST_X1)
      return Op + 1;
    else if (IssueSlot == TileII::ST_Y2)
      return Op + 2;
    else
      llvm_unreachable("mismatch IssueSlot and IssueType!");
  case TileII::IT_X0X1Y0Y1:
    assert((IssueSlot == TileII::ST_X0 || IssueSlot == TileII::ST_X1 ||
            IssueSlot == TileII::ST_Y0 || IssueSlot == TileII::ST_Y1) &&
           "mismatch IssueSlot and IssueType!");
    return Op + IssueSlot;
  default:
    llvm_unreachable("IT_None and IT_Num shouldn't be here!");
  }
}

void llvm::LowerTileMachineInstrToMCInst(const MachineInstr *MI, MCInst &OutMI,
                                         AsmPrinter &AP) {
  // When we reach here, the instruction sequences are
  // bundled already, each instruction has been assigned
  // a issue slot.
  //
  // We should lower MachineInstr to the MCInst for specified
  // slot, because instruction encoding depends on issue slot.

  TileMCInst &TileOutMI = (TileMCInst &)OutMI;
  unsigned MappedOp = MI->getOpcode();
  const TileII::TileIssueType IssueType = (TileII::TileIssueType)(
      (MI->getDesc().TSFlags >> TileII::IssueTypePos) & TileII::IssueTypeMask);
  if (!TileOutMI.isSoloInst())
    MappedOp =
        mapToOpcodeWithIssueSlot(MappedOp, TileOutMI.getIssueSlot(), IssueType);
  OutMI.setOpcode(MappedOp);

  for (unsigned i = 0, e = MI->getNumOperands(); i != e; ++i) {
    const MachineOperand &MO = MI->getOperand(i);

    MCOperand MCOp;
    switch (MO.getType()) {
    default:
      MI->dump();
      llvm_unreachable("unknown operand type");
    case MachineOperand::MO_Register:
      assert(!MO.getSubReg() && "Subregs should be eliminated!");
      MCOp = MCOperand::CreateReg(MO.getReg());
      break;
    case MachineOperand::MO_Immediate:
      MCOp = MCOperand::CreateImm(MO.getImm());
      break;
    case MachineOperand::MO_MachineBasicBlock:
      MCOp = MCOperand::CreateExpr(
          MCSymbolRefExpr::Create(MO.getMBB()->getSymbol(), AP.OutContext));
      break;
    case MachineOperand::MO_GlobalAddress:
      MCOp = GetSymbolRef(MO, AP.Mang->getSymbol(MO.getGlobal()), AP);
      break;
    case MachineOperand::MO_ExternalSymbol:
      MCOp =
          GetSymbolRef(MO, AP.GetExternalSymbolSymbol(MO.getSymbolName()), AP);
      break;
    case MachineOperand::MO_JumpTableIndex:
      MCOp = GetSymbolRef(MO, AP.GetJTISymbol(MO.getIndex()), AP);
      break;
    case MachineOperand::MO_ConstantPoolIndex:
      MCOp = GetSymbolRef(MO, AP.GetCPISymbol(MO.getIndex()), AP);
      break;
    case MachineOperand::MO_BlockAddress:
      MCOp =
          GetSymbolRef(MO, AP.GetBlockAddressSymbol(MO.getBlockAddress()), AP);
      break;
    case MachineOperand::MO_RegisterMask:
      continue;
    }

    OutMI.addOperand(MCOp);
  }
}
