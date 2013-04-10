//===-- TileParser.cpp - Parse Tile assembly to MCInst instructions ----===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#include "TileMCInst.h"
#include "TileRegisterInfo.h"
#include "MCTargetDesc/TileMCTargetDesc.h"
#include "llvm/ADT/StringSwitch.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/MC/MCParser/MCAsmLexer.h"
#include "llvm/MC/MCParser/MCParsedAsmOperand.h"
#include "llvm/MC/MCTargetAsmParser.h"
#include "llvm/Support/TargetRegistry.h"

using namespace llvm;

namespace {
class TileAsmParser : public MCTargetAsmParser {

  MCSubtargetInfo &STI;
  MCAsmParser &Parser;
  MCAsmParser &getParser() const { return Parser; }

#define GET_ASSEMBLER_HEADER
#include "TileGenAsmMatcher.inc"

  bool MatchAndEmitInstruction(SMLoc IDLoc, unsigned &Opcode,
                               SmallVectorImpl<MCParsedAsmOperand *> &Operands,
                               MCStreamer &Out, unsigned &ErrorInfo,
                               bool MatchingInlineAsm);

  bool ParseRegister(unsigned &RegNo, SMLoc &StartLoc, SMLoc &EndLoc);
  bool ParseOperand(SmallVectorImpl<MCParsedAsmOperand *> &,
                    StringRef Mnemonic);
  bool ParseInstruction(ParseInstructionInfo &Info, StringRef Name,
                        SMLoc NameLoc,
                        SmallVectorImpl<MCParsedAsmOperand *> &Operands);
  bool ParseDirective(AsmToken DirectiveID);
  unsigned validateTargetOperandClass(MCParsedAsmOperand *Op, unsigned Kind);
  int tryParseRegister(StringRef Mnemonic);
  bool tryParseRegisterOperand(SmallVectorImpl<MCParsedAsmOperand *> &Operands,
                               StringRef Mnemonic);
  bool tryParseRelocOperand(SmallVectorImpl<MCParsedAsmOperand *> &Operands,
                            StringRef Mnemonic);
  MCSymbolRefExpr::VariantKind getVariantKind(StringRef Symbol);
  int matchRegisterName(StringRef Symbol, StringRef Mnemonic);
  int matchRegisterByNumber(unsigned RegNum, StringRef Mnemonic);
  unsigned getReg(int RC, int RegNo);
  bool require32bit(StringRef Mnemonic);
  bool isRelocKeyWord(StringRef Mnemonic);

public:
  TileAsmParser(MCSubtargetInfo &sti, MCAsmParser &parser)
      : MCTargetAsmParser(), STI(sti), Parser(parser) {}

};
}

namespace {
// Instances of this class represent a parsed Tile machine instruction.
class TileOperand : public MCParsedAsmOperand {

  enum KindTy {
    k_CondCode,
    k_CoprocNum,
    k_Immediate,
    k_Memory,
    k_PostIndexRegister,
    k_Register,
    k_Token
  } Kind;

  TileOperand(KindTy K) : MCParsedAsmOperand(), Kind(K) {}

  union {
    struct {
      const char *Data;
      unsigned Length;
    } Tok;

    struct {
      unsigned RegNum;
    } Reg;

    struct {
      const MCExpr *Val;
    } Imm;

    struct {
      unsigned Base;
      const MCExpr *Off;
    } Mem;
  };

  SMLoc StartLoc, EndLoc;

public:
  void addRegOperands(MCInst &Inst, unsigned N) const {
    assert(N == 1 && "Invalid number of operands!");
    Inst.addOperand(MCOperand::CreateReg(getReg()));
  }

  void addExpr(MCInst &Inst, const MCExpr *Expr) const {
    // Add as immediate when possible.  Null MCExpr = 0.
    if (Expr == 0)
      Inst.addOperand(MCOperand::CreateImm(0));
    else if (const MCConstantExpr *CE = dyn_cast<MCConstantExpr>(Expr))
      Inst.addOperand(MCOperand::CreateImm(CE->getValue()));
    else
      Inst.addOperand(MCOperand::CreateExpr(Expr));
  }

  void addImmOperands(MCInst &Inst, unsigned N) const {
    assert(N == 1 && "Invalid number of operands!");
    const MCExpr *Expr = getImm();
    addExpr(Inst, Expr);
  }

  void addMemOperands(MCInst &Inst, unsigned N) const {
    assert(N == 2 && "Invalid number of operands!");

    Inst.addOperand(MCOperand::CreateReg(getMemBase()));

    const MCExpr *Expr = getMemOff();
    addExpr(Inst, Expr);
  }

  bool isReg() const { return Kind == k_Register; }
  bool isImm() const { return Kind == k_Immediate; }
  bool isToken() const { return Kind == k_Token; }
  bool isMem() const { return Kind == k_Memory; }

  StringRef getToken() const {
    assert(Kind == k_Token && "Invalid access!");
    return StringRef(Tok.Data, Tok.Length);
  }

  unsigned getReg() const {
    assert((Kind == k_Register) && "Invalid access!");
    return Reg.RegNum;
  }

  const MCExpr *getImm() const {
    assert((Kind == k_Immediate) && "Invalid access!");
    return Imm.Val;
  }

  unsigned getMemBase() const {
    assert((Kind == k_Memory) && "Invalid access!");
    return Mem.Base;
  }

  const MCExpr *getMemOff() const {
    assert((Kind == k_Memory) && "Invalid access!");
    return Mem.Off;
  }

  static TileOperand *CreateToken(StringRef Str, SMLoc S) {
    TileOperand *Op = new TileOperand(k_Token);
    Op->Tok.Data = Str.data();
    Op->Tok.Length = Str.size();
    Op->StartLoc = S;
    Op->EndLoc = S;
    return Op;
  }

  static TileOperand *CreateReg(unsigned RegNum, SMLoc S, SMLoc E) {
    TileOperand *Op = new TileOperand(k_Register);
    Op->Reg.RegNum = RegNum;
    Op->StartLoc = S;
    Op->EndLoc = E;
    return Op;
  }

  static TileOperand *CreateImm(const MCExpr *Val, SMLoc S, SMLoc E) {
    TileOperand *Op = new TileOperand(k_Immediate);
    Op->Imm.Val = Val;
    Op->StartLoc = S;
    Op->EndLoc = E;
    return Op;
  }

  static TileOperand *
  CreateMem(unsigned Base, const MCExpr *Off, SMLoc S, SMLoc E) {
    TileOperand *Op = new TileOperand(k_Memory);
    Op->Mem.Base = Base;
    Op->Mem.Off = Off;
    Op->StartLoc = S;
    Op->EndLoc = E;
    return Op;
  }

  // Get the location of the first token of this operand.
  SMLoc getStartLoc() const { return StartLoc; }
  // Get the location of the last token of this operand.
  SMLoc getEndLoc() const { return EndLoc; }

  virtual void print(raw_ostream &OS) const {
    llvm_unreachable("unimplemented!");
  }
};
}

MCSymbolRefExpr::VariantKind TileAsmParser::getVariantKind(StringRef Symbol) {

  MCSymbolRefExpr::VariantKind VK =
      StringSwitch<MCSymbolRefExpr::VariantKind>(Symbol)
      .Case("plt", MCSymbolRefExpr::VK_Tile_PLT_CALL)
      .Case("hw0", MCSymbolRefExpr::VK_Tile_HW0)
      .Case("hw1", MCSymbolRefExpr::VK_Tile_HW1)
      .Case("hw0_last", MCSymbolRefExpr::VK_Tile_HW0_LAST)
      .Case("hw1_last", MCSymbolRefExpr::VK_Tile_HW1_LAST)
      .Case("hw2_last", MCSymbolRefExpr::VK_Tile_HW2_LAST)
      .Case("hw0_got", MCSymbolRefExpr::VK_Tile_HW0_GOT)
      .Case("hw1_last_got", MCSymbolRefExpr::VK_Tile_HW1_LAST_GOT)
      .Case("tls_add", MCSymbolRefExpr::VK_Tile_TLS_ADD)
      .Case("tls_gd_call", MCSymbolRefExpr::VK_Tile_TLS_GD_CALL)
      .Case("tls_gd_add", MCSymbolRefExpr::VK_Tile_TLS_GD_ADD)
      .Case("tls_ie_load", MCSymbolRefExpr::VK_Tile_TLS_IE_LOAD)
      .Case("hw0_tls_gd", MCSymbolRefExpr::VK_Tile_HW0_TLS_GD)
      .Case("hw0_tls_ie", MCSymbolRefExpr::VK_Tile_HW0_TLS_IE)
      .Case("hw0_tls_le", MCSymbolRefExpr::VK_Tile_HW0_TLS_LE)
      .Case("hw1_last_tls_gd", MCSymbolRefExpr::VK_Tile_HW1_LAST_TLS_GD)
      .Case("hw1_last_tls_ie", MCSymbolRefExpr::VK_Tile_HW1_LAST_TLS_IE)
      .Case("hw1_last_tls_le", MCSymbolRefExpr::VK_Tile_HW1_LAST_TLS_LE)
      .Default(MCSymbolRefExpr::VK_None);

  return VK;
}

bool TileAsmParser::isRelocKeyWord(StringRef Mnemonic) {
  return (Mnemonic.equals("hw0") || Mnemonic.equals("hw1") ||
          Mnemonic.equals("hw2") || Mnemonic.equals("hw1_last") ||
          Mnemonic.equals("hw2_last") || Mnemonic.equals("hw0_got") ||
          Mnemonic.equals("hw1_last_got") || Mnemonic.equals("plt") ||
          Mnemonic.equals("tls_add") || Mnemonic.equals("tls_gd_call") ||
          Mnemonic.equals("tls_gd_add") || Mnemonic.equals("tls_ie_load") ||
          Mnemonic.equals("hw0_tls_gd") || Mnemonic.equals("hw0_tls_ie") ||
          Mnemonic.equals("hw0_tls_le") || Mnemonic.equals("hw1_last_tls_gd") ||
          Mnemonic.equals("hw1_last_tls_ie") ||
          Mnemonic.equals("hw1_last_tls_le"));
}

bool TileAsmParser::require32bit(StringRef Mnemonic) {
  return (Mnemonic.equals("st4") || Mnemonic.equals("addx") ||
          Mnemonic.equals("subx") || Mnemonic.equals("shlx") ||
          Mnemonic.equals("shlxi") || Mnemonic.equals("shrux") ||
          Mnemonic.equals("shruxi") || Mnemonic.equals("addxi") ||
          Mnemonic.equals("addxli") || Mnemonic.equals("fetchadd4") ||
          Mnemonic.equals("fetchand4") || Mnemonic.equals("fetchor4") ||
          Mnemonic.equals("exch4") || Mnemonic.equals("mulx"));
}

int TileAsmParser::matchRegisterName(StringRef Name, StringRef Mnemonic) {
  int CC = StringSwitch<unsigned>(Name).Case("fp", Tile::FP)
      .Case("tp", Tile::TP).Case("sp", Tile::SP).Case("lr", Tile::LR)
      .Case("zero", Tile::ZERO).Default(-1);

  if (CC == -1)
    return -1;

  if (require32bit(Mnemonic))
    ++CC;
  return CC;
}

bool TileAsmParser::MatchAndEmitInstruction(
    SMLoc IDLoc, unsigned &Opcode,
    SmallVectorImpl<MCParsedAsmOperand *> &Operands, MCStreamer &Out,
    unsigned &ErrorInfo, bool MatchingInlineAsm) {
  TileMCInst Inst;
  unsigned MatchResult =
      MatchInstructionImpl(Operands, Inst, ErrorInfo, MatchingInlineAsm);
  // Currently, we only support the un-bundled format, ie.
  //
  //   addi sp, sp, -24
  //   addi r0, r1, -24
  //
  // no support of instruction bundle format,
  //
  //   {
  //   addi sp, sp, -24
  //   addi r0, r1, -24
  //   }
  Inst.setIssueSlot(TileII::ST_Solo);

  switch (MatchResult) {
  default:
    break;
  case Match_Success: {
    Inst.setLoc(IDLoc);
    Out.EmitInstruction(Inst);
    return false;
  }
  case Match_MissingFeature:
    Error(IDLoc, "instruction requires a CPU feature not currently enabled");
    return true;
  case Match_InvalidOperand: {
    SMLoc ErrorLoc = IDLoc;
    if (ErrorInfo == ~0U)
      return Error(ErrorLoc, "invalid operand for instruction");

    if (ErrorInfo >= Operands.size())
      return Error(IDLoc, "too few operands for instruction");

    ErrorLoc = ((TileOperand *)Operands[ErrorInfo])->getStartLoc();
    if (ErrorLoc == SMLoc())
      ErrorLoc = IDLoc;

    return Error(ErrorLoc, "invalid operand for instruction");
  }
  case Match_MnemonicFail:
    return Error(IDLoc, "invalid instruction");
  }
  return true;
}

unsigned TileAsmParser::getReg(int RC, int RegNo) {
  return *(getContext().getRegisterInfo().getRegClass(RC).begin() + RegNo);
}

int TileAsmParser::matchRegisterByNumber(unsigned RegNum, StringRef Mnemonic) {

  if (RegNum > 63)
    return -1;

  if (require32bit(Mnemonic))
    return getReg(Tile::CPU32RegsRegClassID, RegNum);
  else
    return getReg(Tile::CPURegsRegClassID, RegNum);
}

int TileAsmParser::tryParseRegister(StringRef Mnemonic) {
  const AsmToken &Tok = Parser.getTok();
  int RegNum = -1;

  if (!Tok.is(AsmToken::Identifier))
    return RegNum;

  std::string lowerCase = Tok.getString().lower();
  if (lowerCase[0] == 'r') {
    int Value;
    StringRef Num(lowerCase.c_str() + 1);
    if (!Num.getAsInteger(10, Value))
      RegNum = matchRegisterByNumber(Value, Mnemonic.lower());
  } else
    RegNum = matchRegisterName(lowerCase, Mnemonic.lower());

  return RegNum;
}

bool TileAsmParser::ParseRegister(unsigned &RegNo, SMLoc &StartLoc,
                                  SMLoc &EndLoc) {
  StartLoc = Parser.getTok().getLoc();
  RegNo = tryParseRegister("");
  EndLoc = Parser.getTok().getLoc();
  return (RegNo == (unsigned) - 1);
}

bool TileAsmParser::tryParseRelocOperand(
    SmallVectorImpl<MCParsedAsmOperand *> &Operands, StringRef Mnemonic) {

  const MCExpr *IdVal, *Res;
  const AsmToken &Tok = Parser.getTok();
  std::string RKey = Tok.getString().lower();
  SMLoc S, E;

  if (!isRelocKeyWord(RKey))
    return true;

  S = Tok.getLoc();
  // Eat the reloc key word.
  Parser.Lex();

  // Now make expression from the rest of the operand.
  SMLoc EndLoc;

  if (getLexer().getKind() == AsmToken::LParen) {
    // Eat '(' token.
    Parser.Lex();
    if (Parser.parseParenExpression(IdVal, EndLoc))
      return true;
  } else
    return true; // Parenthesis must follow reloc operand.

  if (const MCSymbolRefExpr *MSRE = dyn_cast<MCSymbolRefExpr>(IdVal)) {
    // It's a symbol, create symbolic expression from symbol.
    StringRef Symbol = MSRE->getSymbol().getName();
    MCSymbolRefExpr::VariantKind VK = getVariantKind(RKey);
    Res = MCSymbolRefExpr::Create(Symbol, VK, getContext());
    E = SMLoc::getFromPointer(Parser.getTok().getLoc().getPointer() - 1);
    Operands.push_back(TileOperand::CreateImm(Res, S, E));
    return false;
  }

  return true;
}

bool TileAsmParser::tryParseRegisterOperand(
    SmallVectorImpl<MCParsedAsmOperand *> &Operands, StringRef Mnemonic) {

  SMLoc S = Parser.getTok().getLoc();
  int RegNo = -1;

  RegNo = tryParseRegister(Mnemonic);

  if (RegNo == -1)
    return true;

  Operands.push_back(
      TileOperand::CreateReg(RegNo, S, Parser.getTok().getLoc()));
  Parser.Lex(); // Eat register token.
  return false;
}

bool TileAsmParser::ParseOperand(
    SmallVectorImpl<MCParsedAsmOperand *> &Operands, StringRef Mnemonic) {

  switch (getLexer().getKind()) {
  default:
    Error(Parser.getTok().getLoc(), "unexpected token in operand");
    return true;
  case AsmToken::Identifier:
    if (!tryParseRegisterOperand(Operands, Mnemonic))
      return false;
    else if (!tryParseRelocOperand(Operands, Mnemonic))
      return false;
  case AsmToken::LParen:
  case AsmToken::Minus:
  case AsmToken::Plus:
  case AsmToken::Integer:
  case AsmToken::String: {
    // Quoted label names.
    const MCExpr *IdVal;
    SMLoc S = Parser.getTok().getLoc();
    if (getParser().parseExpression(IdVal))
      return true;
    SMLoc E = SMLoc::getFromPointer(Parser.getTok().getLoc().getPointer() - 1);
    Operands.push_back(TileOperand::CreateImm(IdVal, S, E));
    return false;
  }
  }
  return true;
}

bool TileAsmParser::ParseInstruction(
    ParseInstructionInfo &Info, StringRef Name, SMLoc NameLoc,
    SmallVectorImpl<MCParsedAsmOperand *> &Operands) {
  Operands.push_back(TileOperand::CreateToken(Name, NameLoc));

  // Read the remaining operands.
  if (getLexer().isNot(AsmToken::EndOfStatement)) {
    // Read the first operand.
    if (ParseOperand(Operands, Name)) {
      SMLoc Loc = getLexer().getLoc();
      Parser.eatToEndOfStatement();
      return Error(Loc, "unexpected token in argument list");
    }

    while (getLexer().is(AsmToken::Comma)) {
      Parser.Lex(); // Eat the comma.

      // Parse and remember the operand.
      if (ParseOperand(Operands, Name)) {
        SMLoc Loc = getLexer().getLoc();
        Parser.eatToEndOfStatement();
        return Error(Loc, "unexpected token in argument list");
      }
    }
  }

  if (getLexer().isNot(AsmToken::EndOfStatement)) {
    SMLoc Loc = getLexer().getLoc();
    Parser.eatToEndOfStatement();
    return Error(Loc, "unexpected token in argument list");
  }

  Parser.Lex(); // Consume the EndOfStatement.
  return false;
}

bool TileAsmParser::ParseDirective(AsmToken DirectiveID) { return true; }

extern "C" void LLVMInitializeTileAsmParser() {
  RegisterMCAsmParser<TileAsmParser> X(TheTileGXTarget);
}

#define GET_REGISTER_MATCHER
#define GET_MATCHER_IMPLEMENTATION
#include "TileGenAsmMatcher.inc"

// Define this matcher function after the auto-generated include, so we
// have the match class enum definitions.
unsigned TileAsmParser::validateTargetOperandClass(MCParsedAsmOperand *AsmOp,
                                                   unsigned Kind) {
  TileOperand *Op = static_cast<TileOperand *>(AsmOp);
  if ((Kind == MCK_CPU32Regs || Kind == MCK_CPURegs) && Op->isReg())
    return Match_Success;
  return Match_InvalidOperand;
}
