//===-- TileAsmPrinter.cpp - Tile LLVM Assembly Printer -------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains a printer that converts from our internal representation
// of machine-dependent LLVM code to GAS-format Tile assembly language.
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "tile-asm-printer"
#include "TileAsmPrinter.h"
#include "Tile.h"
#include "TileInstrInfo.h"
#include "TileMCInst.h"
#include "InstPrinter/TileInstPrinter.h"
#include "MCTargetDesc/TileBaseInfo.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/ADT/Twine.h"
//#include "llvm/Analysis/DebugInfo.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Instructions.h"
#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineConstantPool.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/CodeGen/MachineMemOperand.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/CodeGen/MachineJumpTableInfo.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/Support/TargetRegistry.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Target/Mangler.h"
#include "llvm/Target/TargetLoweringObjectFile.h"
#include "llvm/Target/TargetOptions.h"

using namespace llvm;

namespace llvm {
#define BUNDLE_TEMPLATE_MASK(p0, p1, p2) ((p0) | ((p1) << 8) | ((p2) << 16))
#define BUNDLE_TEMPLATE(p0, p1, p2)                                            \
  {                                                                            \
    { (p0), (p1), (p2) }                                                       \
    , BUNDLE_TEMPLATE_MASK(1 << (p0), 1 << (p1), (1 << (p2)))                  \
  }

struct bundle_template {
  unsigned int pipe[3];
  unsigned int pipe_mask;
};

static const struct bundle_template bundle_templates[] = {
  // In Y format we must always have something in Y2, since it has
  // no fnop, so this conveys that Y2 must always be used.
  BUNDLE_TEMPLATE(TileII::ST_Y0, TileII::ST_Y2, TileII::ST_None),
  BUNDLE_TEMPLATE(TileII::ST_Y1, TileII::ST_Y2, TileII::ST_None),
  BUNDLE_TEMPLATE(TileII::ST_Y2, TileII::ST_Y0, TileII::ST_None),
  BUNDLE_TEMPLATE(TileII::ST_Y2, TileII::ST_Y1, TileII::ST_None),

  // Y format has three instructions.
  BUNDLE_TEMPLATE(TileII::ST_Y0, TileII::ST_Y1, TileII::ST_Y2),
  BUNDLE_TEMPLATE(TileII::ST_Y0, TileII::ST_Y2, TileII::ST_Y1),
  BUNDLE_TEMPLATE(TileII::ST_Y1, TileII::ST_Y0, TileII::ST_Y2),
  BUNDLE_TEMPLATE(TileII::ST_Y1, TileII::ST_Y2, TileII::ST_Y0),
  BUNDLE_TEMPLATE(TileII::ST_Y2, TileII::ST_Y0, TileII::ST_Y1),
  BUNDLE_TEMPLATE(TileII::ST_Y2, TileII::ST_Y1, TileII::ST_Y0),

  // X format has only two instructions.
  BUNDLE_TEMPLATE(TileII::ST_X0, TileII::ST_X1, TileII::ST_None),
  BUNDLE_TEMPLATE(TileII::ST_X1, TileII::ST_X0, TileII::ST_None)
};

static const unsigned int slot_mask_map[TileII::IT_Num] = {
  1 << TileII::ST_None,                         // IT_None
  1 << TileII::ST_X0,                           // IT_X0
  1 << TileII::ST_X1,                           // IT_X1
  (1 << TileII::ST_X0) | (1 << TileII::ST_X1),  // IT_X0X1
  (1 << TileII::ST_X0) | (1 << TileII::ST_Y0),  // IT_X0Y0
  (1 << TileII::ST_X1) | (1 << TileII::ST_Y1),  // IT_X1Y1
  (1 << TileII::ST_X1) | (1 << TileII::ST_Y2),  // IT_X1Y2
  (1 << TileII::ST_X0) | (1 << TileII::ST_X1) | // IT_X0X1Y0Y1
  (1 << TileII::ST_Y0) | (1 << TileII::ST_Y1)
};
}

bool TileAsmPrinter::runOnMachineFunction(MachineFunction &MF) {
  TileFI = MF.getInfo<TileFunctionInfo>();
  AsmPrinter::runOnMachineFunction(MF);
  return true;
}

MCSymbol *TileAsmPrinter::GetTileJTIName(unsigned uid) const {
  SmallString<60> Name;
  raw_svector_ostream(Name) << MAI->getPrivateGlobalPrefix() << "JTI"
                            << getFunctionNumber() << '_' << uid;
  return OutContext.GetOrCreateSymbol(Name.str());
}

void TileAsmPrinter::EmitJumpTable(const MachineInstr *MI) {
  int OpNum = 1;
  const MachineOperand &MO1 = MI->getOperand(OpNum);
  unsigned JTI = MO1.getIndex();

  // Emit a label for the jump table.
  MCSymbol *JTISymbol = GetTileJTIName(JTI);
  OutStreamer.EmitLabel(JTISymbol);

  // Emit each entry of the table.
  const MachineJumpTableInfo *MJTI = MF->getJumpTableInfo();
  const std::vector<MachineJumpTableEntry> &JT = MJTI->getJumpTables();
  const std::vector<MachineBasicBlock *> &JTBBs = JT[JTI].MBBs;

  for (unsigned i = 0, e = JTBBs.size(); i != e; ++i) {
    MachineBasicBlock *MBB = JTBBs[i];
    const MCExpr *Expr = MCSymbolRefExpr::Create(MBB->getSymbol(), OutContext);

    if (TM.getRelocationModel() == Reloc::PIC_)
      Expr = MCBinaryExpr::CreateSub(
          Expr, MCSymbolRefExpr::Create(JTISymbol, OutContext), OutContext);
    OutStreamer.EmitValue(Expr, 8);
  }
}

void TileAsmPrinter::EmitInstruction(const MachineInstr *MI) {
  if (MI->isDebugValue()) {
    SmallString<128> Str;
    raw_svector_ostream OS(Str);

    PrintDebugValueComment(MI, OS);
    return;
  }

  if (MI->isBundle()) {
    std::vector<const MachineInstr *> BundleMIs;

    const MachineBasicBlock *MBB = MI->getParent();
    MachineBasicBlock::const_instr_iterator MII = MI;
    ++MII;
    unsigned int IgnoreCount = 0;
    while (MII != MBB->end() && MII->isInsideBundle()) {
      const MachineInstr *MInst = MII;
      if (MInst->getOpcode() == TargetOpcode::DBG_VALUE ||
          MInst->getOpcode() == TargetOpcode::IMPLICIT_DEF) {
        IgnoreCount++;
        ++MII;
        continue;
      }
      BundleMIs.push_back(MInst);
      ++MII;
    }
    unsigned Size = BundleMIs.size();
    assert((Size + IgnoreCount) == MI->getBundleSize() && "Corrupt Bundle!");
    assert((Size > 1) && "Bundled size should > 1!");

#define MASK_INDEX(n)                                                          \
  ((BundleMIs[n]->getDesc().TSFlags >> TileII::IssueTypePos) &                 \
   TileII::IssueTypeMask)
    unsigned compatible_pipes = BUNDLE_TEMPLATE_MASK(
        slot_mask_map[MASK_INDEX(0)], slot_mask_map[MASK_INDEX(1)],
        (Size == 3 ? slot_mask_map[MASK_INDEX(2)] : (1 << TileII::ST_None)));

    const struct bundle_template *match = NULL;
    for (unsigned Index = 0; Index < array_lengthof(bundle_templates);
         Index++) {

      const struct bundle_template *b = &bundle_templates[Index];
      if ((b->pipe_mask & compatible_pipes) == b->pipe_mask) {
        match = b;
        break;
      }
    }

    assert((match != NULL) && "no bundle template found!\n");

    bool SeenJT = false;
    bool SeenLNK = false;
    for (unsigned Index = 0; Index < Size; Index++) {
      TileMCInst MCI;
      MCI.setStartPacket(Index == 0);
      MCI.setEndPacket(Index == (Size - 1));
      MCI.setIssueSlot(match->pipe[Index]);

      LowerTileMachineInstrToMCInst(BundleMIs[Index], MCI, *this);
      OutStreamer.EmitInstruction(MCI);

      if (MCI.getOpcode() == Tile::BRINDJT0_X1)
        SeenJT = true;
      else if (MCI.getOpcode() == Tile::LNK0_X1)
        SeenLNK = true;
    }

    if (SeenJT)
      EmitJumpTable(MI);
    if (SeenLNK)
      OutStreamer.EmitLabel(MF->getPICBaseSymbol());
  } else {
    TileMCInst TmpInst;
    TmpInst.setIssueSlot(TileII::ST_Solo);
    LowerTileMachineInstrToMCInst(MI, TmpInst, *this);
    OutStreamer.EmitInstruction(TmpInst);

    if (MI->getOpcode() == Tile::BRINDJT)
      EmitJumpTable(MI);
    else if (MI->getOpcode() == Tile::LNK)
      OutStreamer.EmitLabel(MF->getPICBaseSymbol());
  }
}

void TileAsmPrinter::EmitFunctionEntryLabel() {
  OutStreamer.EmitLabel(CurrentFnSym);
}

// Return true if the basic block has exactly one predecessor
// and the control transfer mechanism between the predecessor
// and this block is a fall-through.
bool TileAsmPrinter::isBlockOnlyReachableByFallthrough(
    const MachineBasicBlock *MBB) const {
  // The predecessor has to be immediately before this block.
  const MachineBasicBlock *Pred = *MBB->pred_begin();

  // If the predecessor is a switch statement, assume a jump table
  // implementation, so it is not a fall through.
  if (const BasicBlock *bb = Pred->getBasicBlock())
    if (isa<SwitchInst>(bb->getTerminator()))
      return false;

  // If this is a landing pad, it isn't a fall through.  If it has no preds,
  // then nothing falls through to it.
  if (MBB->isLandingPad() || MBB->pred_empty())
    return false;

  // If there isn't exactly one predecessor, it can't be a fall through.
  MachineBasicBlock::const_pred_iterator PI = MBB->pred_begin(), PI2 = PI;
  ++PI2;

  if (PI2 != MBB->pred_end())
    return false;

  // The predecessor has to be immediately before this block.
  if (!Pred->isLayoutSuccessor(MBB))
    return false;

  // If the block is completely empty, then it definitely does fall through.
  if (Pred->empty())
    return true;

  // Otherwise, check the last instruction.
  // Check if the last terminator is an unconditional branch.
  MachineBasicBlock::const_iterator I = Pred->end();
  while (I != Pred->begin() && !(--I)->isTerminator())
    ;

  return !I->isBarrier();
}

// Print out an operand for an inline asm expression.
bool TileAsmPrinter::PrintAsmOperand(const MachineInstr *MI, unsigned OpNo,
                                     unsigned AsmVariant, const char *ExtraCode,
                                     raw_ostream &O) {
  // Does this asm operand have a single letter operand modifier?
  if (ExtraCode && ExtraCode[0]) {
    if (ExtraCode[1] != 0)
      return true; // Unknown modifier.
    else
      return AsmPrinter::PrintAsmOperand(MI, OpNo, AsmVariant, ExtraCode, O);
  }

  printOperand(MI, OpNo, O);
  return false;
}

bool TileAsmPrinter::PrintAsmMemoryOperand(
    const MachineInstr *MI, unsigned OpNum, unsigned AsmVariant,
    const char *ExtraCode, raw_ostream &O) {
  if (ExtraCode && ExtraCode[0])
    return true; // Unknown modifier.

  const MachineOperand &MO = MI->getOperand(OpNum);
  assert(MO.isReg() && "unexpected inline asm memory operand");
  O << "r" << TileInstPrinter::getRegisterName(MO.getReg());
  return false;
}

void TileAsmPrinter::printOperand(const MachineInstr *MI, int opNum,
                                  raw_ostream &O) {
  const MachineOperand &MO = MI->getOperand(opNum);
  bool CloseP = false;

  if (MO.getTargetFlags())
    CloseP = true;

  switch (MO.getTargetFlags()) {
  case TileII::MO_PLT_CALL:
    O << "plt(";
    break;
  case TileII::MO_HW0:
    O << "hw0(";
    break;
  case TileII::MO_HW0_GOT:
    O << "hw0_got(";
    break;
  case TileII::MO_HW0_LAST:
    O << "hw0_last(";
    break;
  case TileII::MO_HW1:
    O << "hw1(";
    break;
  case TileII::MO_HW1_LAST:
    O << "hw1_last(";
    break;
  case TileII::MO_HW1_LAST_GOT:
    O << "hw1_last_got(";
    break;
  case TileII::MO_HW2_LAST:
    O << "hw2_last(";
    break;
  case TileII::MO_HW0_PIC:
    O << "hw0(_GLOBAL_OFFSET_TABLE_ - .L_PICLNK_";
    break;
  case TileII::MO_HW1_LAST_PIC:
    O << "hw1_last(_GLOBAL_OFFSET_TABLE_ - .L_PICLNK_";
    break;
  }

  switch (MO.getType()) {
  case MachineOperand::MO_Register:
    O << StringRef(TileInstPrinter::getRegisterName(MO.getReg())).lower();
    break;

  case MachineOperand::MO_Immediate:
    O << MO.getImm();
    break;

  case MachineOperand::MO_MachineBasicBlock:
    O << *MO.getMBB()->getSymbol();
    return;

  case MachineOperand::MO_GlobalAddress:
    O << *Mang->getSymbol(MO.getGlobal());
    break;

  case MachineOperand::MO_BlockAddress: {
    MCSymbol *BA = GetBlockAddressSymbol(MO.getBlockAddress());
    O << BA->getName();
    break;
  }

  case MachineOperand::MO_ExternalSymbol:
    O << *GetExternalSymbolSymbol(MO.getSymbolName());
    break;

  case MachineOperand::MO_JumpTableIndex:
    O << MAI->getPrivateGlobalPrefix() << "JTI" << getFunctionNumber() << '_'
      << MO.getIndex();
    break;

  case MachineOperand::MO_ConstantPoolIndex:
    O << MAI->getPrivateGlobalPrefix() << "CPI" << getFunctionNumber() << "_"
      << MO.getIndex();
    if (MO.getOffset())
      O << "+" << MO.getOffset();
    break;

  default:
    llvm_unreachable("<unknown operand type>");
  }

  if (CloseP)
    O << ")";
}

void TileAsmPrinter::printUnsignedImm(const MachineInstr *MI, int opNum,
                                      raw_ostream &O) {
  const MachineOperand &MO = MI->getOperand(opNum);
  if (MO.isImm())
    O << (unsigned short int) MO.getImm();
  else
    printOperand(MI, opNum, O);
}

void TileAsmPrinter::EmitStartOfAsmFile(Module &M) {
  // Currently, nothing to do for Tile.
  return;
}

MachineLocation
TileAsmPrinter::getDebugValueLocation(const MachineInstr *MI) const {
  // Handles frame addresses emitted in TileInstrInfo::emitFrameIndexDebugValue.
  assert(MI->getNumOperands() == 4 && "Invalid no. of machine operands!");
  assert(MI->getOperand(0).isReg() && MI->getOperand(1).isImm() &&
         "Unexpected MachineOperand types");
  return MachineLocation(MI->getOperand(0).getReg(),
                         MI->getOperand(1).getImm());
}

void TileAsmPrinter::PrintDebugValueComment(const MachineInstr *MI,
                                            raw_ostream &OS) {
  // TODO: implement
}

// Force static initialization.
extern "C" void LLVMInitializeTileAsmPrinter() {
  RegisterAsmPrinter<TileAsmPrinter> X(TheTileGXTarget);
}
