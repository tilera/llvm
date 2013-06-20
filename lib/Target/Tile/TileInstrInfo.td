//===- TileInstrInfo.td - Target Description for Tile Target -*- tablegen -*-=//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the Tile implementation of the TargetInstrInfo class.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Instruction format superclass.
//===----------------------------------------------------------------------===//

include "TileInstrFormats.td"

//===----------------------------------------------------------------------===//
// Tile profiles and nodes.
//===----------------------------------------------------------------------===//

def SDT_TileRet
    : SDTypeProfile<0, 1, [SDTCisVT<0, iPTR>]>;

def SDT_TileJmpLink
    : SDTypeProfile<0, 1, [SDTCisVT<0, iPTR>]>;

def SDT_TileCMov
    : SDTypeProfile<1, 4, [SDTCisSameAs<0, 1>,
                           SDTCisSameAs<1, 2>,
                           SDTCisSameAs<3, 4>,
                           SDTCisInt<4>]>;

def SDT_TileCallSeqStart
    : SDCallSeqStart<[SDTCisVT<0, i32>]>;

def SDT_TileCallSeqEnd
    : SDCallSeqEnd<[SDTCisVT<0, i32>, SDTCisVT<1, i32>]>;

def SDT_TileMF
    : SDTypeProfile<0, 0, []>;

def SDT_TileBRINDJT
    : SDTypeProfile<0, 2, [SDTCisPtrTy<0>,
                           SDTCisVT<1, i64>]>;

def SDT_TileTLSADD
    : SDTypeProfile<1, 3, [SDTCisSameAs<0, 1>,
                           SDTCisSameAs<0, 2>,
                           SDTCisSameAs<0, 3>,
                           SDTCisInt<0>
]>;

def SDT_TileBFINS
    : SDTypeProfile<1, 4, [SDTCisInt<0>,
                           SDTCisSameAs<0, 1>,
                           SDTCisInt<2>,
                           SDTCisSameAs<2, 3>,
                           SDTCisSameAs<0, 4>]>;

def SDT_TileBFEXTU
    : SDTypeProfile<1, 3, [SDTCisInt<0>,
                           SDTCisInt<2>,
                           SDTCisSameAs<2, 3>]>;

// Call
def TileJmpLink : SDNode<"TileISD::JmpLink",SDT_TileJmpLink,
                         [SDNPHasChain, SDNPOutGlue, SDNPOptInGlue,
                          SDNPVariadic]>;

// TLS
def TileTLSGD
    : SDNode<"TileISD::TLSGD", SDTIntBinOp>;
def TileLDTLS
    : SDNode<"TileISD::LDTLS", SDTIntBinOp>;
def TileTLSRADD0
    : SDNode<"TileISD::TLSRELAXADD0",SDT_TileTLSADD>;
def TileTLSRADD1
    : SDNode<"TileISD::TLSRELAXADD1",SDTIntBinOp>;

def TileMOVE
    : SDNode<"TileISD::MOVE", SDTIntUnaryOp>;
def TileSAR16
    : SDNode<"TileISD::SAR16", SDTIntBinOp>;

def TileVAARG_SPNode
    : SDNode<"TileISD::VAARG_SP", SDTIntBinOp>;
def TileALLOCA_SPNode
    : SDNode<"TileISD::ALLOCA_SP", SDTIntBinOp>;
def TileALLOCA_ADDRNode
    : SDNode<"TileISD::ALLOCA_ADDR", SDTIntBinOp>;

// Return
def TileRetNode
    : SDNode<"TileISD::Ret", SDT_TileRet, [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

// Tile BRINDJT is actually the same with ISD::BRIND,
// we define a target private type here for the purpose
// to generate customized jump table.
def TileBRINDJTNode
    : SDNode<"TileISD::BRINDJT", SDT_TileBRINDJT, [SDNPHasChain]>;

// These are target-independent nodes, but have target-specific formats.
def callseq_start : SDNode<"ISD::CALLSEQ_START", SDT_TileCallSeqStart,
                           [SDNPHasChain, SDNPOutGlue]>;
def callseq_end   : SDNode<"ISD::CALLSEQ_END", SDT_TileCallSeqEnd,
                           [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue]>;

def TileMFNode : SDNode<"TileISD::MF", SDT_TileMF, [SDNPHasChain]>;

def TileBFINSNode : SDNode<"TileISD::BFINS", SDT_TileBFINS>;
def TileBFEXTUNode : SDNode<"TileISD::BFEXTU", SDT_TileBFEXTU>;

// Instruction operand types.
def jmptarget   : Operand<OtherVT> {
  let EncoderMethod = "getJumpTargetOpValue";
}
def brtarget    : Operand<OtherVT> {
  let EncoderMethod = "getBranchTargetOpValue";
  let OperandType = "OPERAND_PCREL";
}
def calltarget  : Operand<iPTR> {
  let EncoderMethod = "getJumpTargetOpValue";
}
def calltarget64: Operand<i64>;

def simm16_32   : Operand<i32> {
  let PrintMethod = "printS16ImmOperand";
}

def simm16_64   : Operand<i64> {
  let PrintMethod = "printS16ImmOperand";
}

def shamt       : Operand<i32>;

def simm8_32   : Operand<i32>;
def simm8_64   : Operand<i64>;

// Unsigned Operand.
def uimm16      : Operand<i64> {
  let PrintMethod = "printUnsignedImm";
}

def PICLNKReg : Operand<i64> {
  let PrintMethod = "printPICLNKReg";
}


// Transformation Function - get the lower 48 bits.
def LO48 : SDNodeXForm<imm, [{
  return getImm(N, N->getZExtValue() & 0xFFFFFFFFFFFFLL);
}]>;

def LO32 : SDNodeXForm<imm, [{
  return getImm(N, N->getZExtValue() & 0xFFFFFFFF);
}]>;

def LO16 : SDNodeXForm<imm, [{
  return getImm(N, N->getZExtValue() & 0xFFFF);
}]>;

// Transformation Function - get the lower 8 bits.
def LO8 : SDNodeXForm<imm, [{
  return getImm(N, N->getZExtValue() & 0xFF);
}]>;

// Transformation Function - get the lower 6 bits.
def LO6 : SDNodeXForm<imm, [{
  return getImm(N, N->getZExtValue() & 0x3F);
}]>;


// Transformation Function - get the higher 16 bits from bit 16.
def HI16 : SDNodeXForm<imm, [{
  return getImm(N, (N->getZExtValue() >> 16) & 0xFFFF);
}]>;

// Transformation Function - get the higher 16 bits from bit 32.
def HI32 : SDNodeXForm<imm, [{
  return getImm(N, (N->getZExtValue() >> 32) & 0xFFFF);
}]>;

// Transformation Function - get the higher 16 bits from bit 48.
def HI48 : SDNodeXForm<imm, [{
  return getImm(N, (N->getZExtValue() >> 48) & 0xFFFF);
}]>;

// Node immediate fits as 8/16-bit sign extended on target immediate.
// e.g. addi, andi
def immSExt8   : PatLeaf<(imm), [{ return isInt<8>(N->getSExtValue()); }]>;
def immSExt16  : PatLeaf<(imm), [{ return isInt<16>(N->getSExtValue()); }]>;
def immSExt32  : PatLeaf<(imm), [{ return isInt<32>(N->getSExtValue()); }]>;
def immSExt48  : PatLeaf<(imm), [{ return isInt<48>(N->getSExtValue()); }]>;
def immSExt64  : PatLeaf<(imm), [{ return isInt<64>(N->getSExtValue()); }]>;

// Node immediate fits as 48-bit zero extended on target immediate.
// The LO48 param means that only the lower 16 bits of the node
// immediate are caught.
def immZExt48  : PatLeaf<(imm), [{
  return ((((uint64_t)N->getZExtValue()) >> 48) & 0xFFFF) == 0;
}], LO48>;

def immZExt32  : PatLeaf<(imm), [{
  return (uint64_t)N->getZExtValue() == (unsigned int)N->getZExtValue();
}], LO32>;

def immZExt16  : PatLeaf<(imm), [{
  if (N->getValueType(0) == MVT::i32)
    return (uint32_t)N->getZExtValue() == (unsigned short)N->getZExtValue();
  else
    return (uint64_t)N->getZExtValue() == (unsigned short)N->getZExtValue();
}], LO16>;

// shamt field must fit in 5 bits.
def immZExt5 : ImmLeaf<i64, [{return Imm == (Imm & 0x1f);}]>;
def immZExt5_32 : ImmLeaf<i32, [{return Imm == (Imm & 0x1f);}]>;

def immZExt6 : ImmLeaf<i64, [{return Imm == (Imm & 0x3f);}]>;
def immZExt6_32 : ImmLeaf<i32, [{return Imm == (Imm & 0x3f);}]>;

def immZExt14 : ImmLeaf<i64, [{return Imm == (Imm & 0x3fff);}]>;


//===----------------------------------------------------------------------===//
// Instructions specific format.
//===----------------------------------------------------------------------===//

multiclass TileADDI {

  def #NAME#
      : TileInstX1Imm8
        <0x3, 0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "addi\t$rd, $rs, $imm8",
         [(set (i64 CPURegs:$rd),
            (add CPURegs:$rs, immSExt8:$imm8))],
         IIC_ALU, FrmImm8, S_X0_X1_Y0_Y1>;

  def #0_X0#
      : TileBundleX0Imm8
        <0x4, 0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "addi\t$rd, $rs, $imm8",
         [],
         IIC_ALU, FrmImm8, S_X0_X1_Y0_Y1>;

  def #0_X1#
      : TileBundleX1Imm8
        <0x3, 0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "addi\t$rd, $rs, $imm8",
         [(set (i64 CPURegs:$rd),
            (add CPURegs:$rs, immSExt8:$imm8))],
         IIC_ALU, FrmImm8, S_X0_X1_Y0_Y1>;

  def #0_Y0#
      : TileBundleY0Imm8
        <0x0,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "addi\t$rd, $rs, $imm8",
         [],
         IIC_ALU, FrmImm8, S_X0_X1_Y0_Y1>;

  def #0_Y1#
      : TileBundleY1Imm8
        <0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "addi\t$rd, $rs, $imm8",
         [],
         IIC_ALU, FrmImm8, S_X0_X1_Y0_Y1>;
}

multiclass TileADDLI {

  def #NAME#
      : TileInstX1Imm16
        <0x0,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm16),
         "addli\t$rd, $rs, $imm16",
         [(set (i64 CPURegs:$rd),
            (add CPURegs:$rs, immSExt16:$imm16))],
         IIC_ALU, FrmImm16, S_X0_X1>;

  def #0_X0#
      : TileBundleX0Imm16
        <0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm16),
         "addli\t$rd, $rs, $imm16",
         [],
         IIC_ALU, FrmImm16, S_X0_X1>;

  def #0_X1#
      : TileBundleX1Imm16
        <0x0,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm16),
         "addli\t$rd, $rs, $imm16",
         [],
         IIC_ALU, FrmImm16, S_X0_X1>;
}

multiclass TileADDXI {

  def #NAME#
      : TileInstX1Imm8
        <0x3, 0x2,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rs, i32imm:$imm8),
         "addxi\t$rd, $rs, $imm8",
         [(set (i32 CPU32Regs:$rd),
            (add CPU32Regs:$rs, immSExt8:$imm8))],
         IIC_ALU, FrmImm8, S_X0_X1_Y0_Y1>;

  def #0_X0#
      : TileBundleX0Imm8
        <0x4, 0x2,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rs, i32imm:$imm8),
         "addxi\t$rd, $rs, $imm8",
         [],
         IIC_ALU, FrmImm8, S_X0_X1_Y0_Y1>;

  def #0_X1#
      : TileBundleX1Imm8
        <0x3, 0x2,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rs, i32imm:$imm8),
         "addxi\t$rd, $rs, $imm8",
         [],
         IIC_ALU, FrmImm8, S_X0_X1_Y0_Y1>;

  def #0_Y0#
      : TileBundleY0Imm8
        <0x1,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rs, i32imm:$imm8),
         "addxi\t$rd, $rs, $imm8",
         [],
         IIC_ALU, FrmImm8, S_X0_X1_Y0_Y1>;

  def #0_Y1#
      : TileBundleY1Imm8
        <0x2,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rs, i32imm:$imm8),
         "addxi\t$rd, $rs, $imm8",
         [],
         IIC_ALU, FrmImm8, S_X0_X1_Y0_Y1>;
}

multiclass TileADDXLI {

  def #NAME#
      : TileInstX1Imm16
        <0x1,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rs, i32imm:$imm16),
         "addxli\t$rd, $rs, $imm16",
         [(set (i32 CPU32Regs:$rd),
            (add CPU32Regs:$rs, immSExt16:$imm16))],
         IIC_ALU, FrmImm16, S_X0_X1>;

  def #0_X0#
      : TileBundleX0Imm16
        <0x2,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rs, i32imm:$imm16),
         "addxli\t$rd, $rs, $imm16",
         [],
         IIC_ALU, FrmImm16, S_X0_X1>;

  def #0_X1#
      : TileBundleX1Imm16
        <0x1,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rs, i32imm:$imm16),
         "addxli\t$rd, $rs, $imm16",
         [],
         IIC_ALU, FrmImm16, S_X0_X1>;
}

let isCommutable = 1 in
multiclass TileADD {

  def #NAME#
      : TileInstX1RRR
        <0x5, 0x3,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "add\t$rd, $rsa, $rsb",
         [(set (i64 CPURegs:$rd),
            (add CPURegs:$rsa, CPURegs:$rsb))],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;

  // These 0_XXX are for encoding only.
  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x3,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "add\t$rd, $rsa, $rsb",
         [],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X1#
      : TileBundleX1RRR
        <0x5, 0x3,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "add\t$rd, $rsa, $rsb",
         [],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y0#
      : TileBundleY0RRR
        <0x5, 0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "add\t$rd, $rsa, $rsb",
         [],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y1#
      : TileBundleY1RRR
        <0x6, 0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "add\t$rd, $rsa, $rsb",
         [],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;
}

let isCommutable = 1 in
multiclass TileADDX {

  def #NAME#
      : TileInstX1RRR
        <0x5, 0x2,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "addx\t$rd, $rsa, $rsb",
         [(set (i32 CPU32Regs:$rd),
           (add CPU32Regs:$rsa, CPU32Regs:$rsb))],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x2,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "addx\t$rd, $rsa, $rsb",
         [],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X1#
      : TileBundleX1RRR
        <0x5, 0x2,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "addx\t$rd, $rsa, $rsb",
         [],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y0#
      : TileBundleY0RRR
        <0x5, 0x0,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "addx\t$rd, $rsa, $rsb",
         [],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y1#
      : TileBundleY1RRR
        <0x5, 0x2,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "addx\t$rd, $rsa, $rsb",
         [],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;
}

let isCodeGenOnly = 1 in
multiclass TileADD_EXTEND {

  def #NAME#
      : TileInstX1RRZ
        <0x5, 0x2,
         (outs CPURegs:$rd),
         (ins CPU32Regs:$rs),
         "addx\t$rd, $rs, zero",
         [],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X0#
      : TileBundleX0RRZ
        <0x5, 0x2,
         (outs CPURegs:$rd),
         (ins CPU32Regs:$rs),
         "addx\t$rd, $rs, zero",
         [],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X1#
      : TileBundleX1RRZ
        <0x5, 0x2,
         (outs CPURegs:$rd),
         (ins CPU32Regs:$rs),
         "addx\t$rd, $rs, zero",
         [],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y0#
      : TileBundleY0RRZ
        <0x5, 0x0,
         (outs CPURegs:$rd),
         (ins CPU32Regs:$rs),
         "addx\t$rd, $rs, zero",
         [],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y1#
      : TileBundleY1RRZ
        <0x5, 0x2,
         (outs CPURegs:$rd),
         (ins CPU32Regs:$rs),
         "addx\t$rd, $rs, zero",
         [],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;
}

let isCodeGenOnly = 1 in
multiclass TileADD_TRUNC {

  def #NAME#
      : TileInstX1RRZ
        <0x5, 0x2,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rs),
         "addx\t$rd, $rs, zero",
         [],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X0#
      : TileBundleX0RRZ
        <0x5, 0x2,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rs),
         "addx\t$rd, $rs, zero",
         [],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X1#
      : TileBundleX1RRZ
        <0x5, 0x2,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rs),
         "addx\t$rd, $rs, zero",
         [],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y0#
      : TileBundleY0RRZ
        <0x5, 0x0,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rs),
         "addx\t$rd, $rs, zero",
         [],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y1#
      : TileBundleY1RRZ
        <0x5, 0x2,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rs),
         "addx\t$rd, $rs, zero",
         [],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;
}

multiclass TileSUB {

  def #NAME#
      : TileInstX1RRR
        <0x5, 0x34,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "sub\t$rd, $rsa, $rsb",
         [(set (i64 CPURegs:$rd),
         (sub CPURegs:$rsa, CPURegs:$rsb))],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x51,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "sub\t$rd, $rsa, $rsb",
         [],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X1#
      : TileBundleX1RRR
        <0x5, 0x34,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "sub\t$rd, $rsa, $rsb",
         [],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y0#
      : TileBundleY0RRR
        <0x5, 0x3,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "sub\t$rd, $rsa, $rsb",
         [],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y1#
      : TileBundleY1RRR
        <0x6, 0x3,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "sub\t$rd, $rsa, $rsb",
         [],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;
}

multiclass TileSUBX {

  def #NAME#
      : TileInstX1RRR
        <0x5, 0x33,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "subx\t$rd, $rsa, $rsb",
         [(set (i32 CPU32Regs:$rd),
            (sub CPU32Regs:$rsa, CPU32Regs:$rsb))],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x50,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "subx\t$rd, $rsa, $rsb",
         [],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X1#
      : TileBundleX1RRR
        <0x5, 0x33,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "subx\t$rd, $rsa, $rsb",
         [],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y0#
      : TileBundleY0RRR
        <0x5, 0x2,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "subx\t$rd, $rsa, $rsb",
         [],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y1#
      : TileBundleY1RRR
        <0x6, 0x2,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "subx\t$rd, $rsa, $rsb",
         [],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;
}

let isCommutable = 1 in
multiclass TileAND {

  def #NAME#
      : TileInstX1RRR
        <0x5, 0x4,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "and\t$rd, $rsa, $rsb",
         [(set (i64 CPURegs:$rd),
         (and CPURegs:$rsa, CPURegs:$rsb))],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x4,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "and\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X1#
      : TileBundleX1RRR
        <0x5, 0x4,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "and\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y0#
      : TileBundleY0RRR
        <0xA, 0x0,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "and\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y1#
      : TileBundleY1RRR
        <0xB, 0x3,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "and\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  let isCodeGenOnly = 1 in
  def #32#
      : TileInstX1RRR
        <0x5, 0x4,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "and\t$rd, $rsa, $rsb",
         [(set (i32 CPU32Regs:$rd),
         (and CPU32Regs:$rsa, CPU32Regs:$rsb))],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;
}

multiclass TileANDI {

  def #NAME#
      : TileInstX1Imm8
        <0x3, 0x3,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "andi\t$rd, $rs, $imm8",
         [(set (i64 CPURegs:$rd),
         (and CPURegs:$rs, immSExt8:$imm8))],
         IIC_LOGIC, FrmImm8, S_X0_X1_Y0_Y1>;

  def #0_X0#
      : TileBundleX0Imm8
        <0x4, 0x3,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "andi\t$rd, $rs, $imm8",
         [],
         IIC_LOGIC, FrmImm8, S_X0_X1_Y0_Y1>;

  def #0_X1#
      : TileBundleX1Imm8
        <0x5, 0x4,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "andi\t$rd, $rs, $imm8",
         [],
         IIC_LOGIC, FrmImm8, S_X0_X1_Y0_Y1>;

  def #0_Y0#
      : TileBundleY0Imm8
        <0x2,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "andi\t$rd, $rs, $imm8",
         [],
         IIC_LOGIC, FrmImm8, S_X0_X1_Y0_Y1>;

  def #0_Y1#
      : TileBundleY1Imm8
        <0x3,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "andi\t$rd, $rs, $imm8",
         [],
         IIC_LOGIC, FrmImm8, S_X0_X1_Y0_Y1>;

  let isCodeGenOnly = 1 in
  def #32#
      : TileInstX1Imm8
        <0x3, 0x3,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rs, i32imm:$imm8),
         "andi\t$rd, $rs, $imm8",
         [(set (i32 CPU32Regs:$rd),
         (and CPU32Regs:$rs, immSExt8:$imm8))],
         IIC_LOGIC, FrmImm8, S_X0_X1_Y0_Y1>;
}

let isCommutable = 1 in
multiclass TileXOR {

  def #NAME#
      : TileInstX1RRR
        <0x5, 0x6B,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "xor\t$rd, $rsa, $rsb",
         [(set (i64 CPURegs:$rd),
         (xor CPURegs:$rsa, CPURegs:$rsb))],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0xA0,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "xor\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X1#
      : TileBundleX1RRR
        <0x5, 0x6B,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "xor\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y0#
      : TileBundleY0RRR
        <0xA, 0x3,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "xor\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y1#
      : TileBundleY1RRR
        <0xB, 0x3,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "xor\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  let isCodeGenOnly = 1 in
  def #32#
      : TileInstX1RRR
        <0x5, 0x6B,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "xor\t$rd, $rsa, $rsb",
         [(set (i32 CPU32Regs:$rd),
         (xor CPU32Regs:$rsa, CPU32Regs:$rsb))],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;
}

let isCommutable = 1 in
multiclass TileOR {

  def #NAME#
      : TileInstX1RRR
        <0x5, 0x1D,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "or\t$rd, $rsa, $rsb",
         [(set (i64 CPURegs:$rd),
         (or CPURegs:$rsa, CPURegs:$rsb))],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x41,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "or\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X1#
      : TileBundleX1RRR
        <0x5, 0x1D,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "or\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y0#
      : TileBundleY0RRR
        <0xA, 0x2,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "or\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y1#
      : TileBundleY1RRR
        <0xA, 0x2,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "or\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  let isCodeGenOnly = 1 in
  def #32# 
      : TileInstX1RRR
        <0x5, 0x1D,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "or\t$rd, $rsa, $rsb",
         [(set (i32 CPU32Regs:$rd),
         (or CPU32Regs:$rsa, CPU32Regs:$rsb))],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;
}

multiclass TileXORI {

  def #NAME#
      : TileInstX1Imm8
        <0x3, 0x2D,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "xori\t$rd, $rs, $imm8",
         [(set (i64 CPURegs:$rd),
           (xor CPURegs:$rs, immSExt8:$imm8))],
         IIC_LOGIC, FrmImm8, S_X0_X1>;

  def #0_X0#
      : TileBundleX0Imm8
        <0x4, 0x14,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "xori\t$rd, $rs, $imm8",
         [],
         IIC_LOGIC, FrmImm8, S_X0_X1>;

  def #0_X1#
      : TileBundleX1Imm8
        <0x3, 0x2D,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "xori\t$rd, $rs, $imm8",
         [],
         IIC_LOGIC, FrmImm8, S_X0_X1>;

  let isCodeGenOnly = 1 in
  def #32#
      : TileInstX1Imm8
        <0x3, 0x2D,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rs, i32imm:$imm8),
         "xori\t$rd, $rs, $imm8",
         [(set (i32 CPU32Regs:$rd),
           (xor CPU32Regs:$rs, immSExt8:$imm8))],
         IIC_LOGIC, FrmImm8, S_X0_X1>;
}

multiclass TileORI {

  def #NAME#
      : TileInstX1Imm8
        <0x3, 0x18,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "ori\t$rd, $rs, $imm8",
         [(set (i64 CPURegs:$rd),
         (or CPURegs:$rs, immSExt8:$imm8))],
         IIC_LOGIC, FrmImm8, S_X0_X1>;

  def #0_X0#
      : TileBundleX0Imm8
        <0x4, 0x7,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "ori\t$rd, $rs, $imm8",
         [],
         IIC_LOGIC, FrmImm8, S_X0_X1>;

  def #0_X1#
      : TileBundleX1Imm8
        <0x3, 0x18,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "ori\t$rd, $rs, $imm8",
         [],
         IIC_LOGIC, FrmImm8, S_X0_X1>;

  let isCodeGenOnly = 1 in
  def #32#
      : TileInstX1Imm8
        <0x3, 0x18,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rs, i32imm:$imm8),
         "ori\t$rd, $rs, $imm8",
         [(set (i32 CPU32Regs:$rd),
         (or CPU32Regs:$rs, immSExt8:$imm8))],
         IIC_LOGIC, FrmImm8, S_X0_X1>;
}

let isCommutable = 1 in
multiclass TileNOR {

  def #NAME#
      : TileInstX1RRR
        <0x5, 0x1C,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "nor\t$rd, $rsa, $rsb",
         [(set (i64 CPURegs:$rd),
         (not (or CPURegs:$rsa, CPURegs:$rsb)))],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x40,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "nor\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X1#
      : TileBundleX1RRR
        <0x5, 0x1C,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "nor\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y0#
      : TileBundleY0RRR
        <0xA, 0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "nor\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y1#
      : TileBundleY1RRR
        <0xB, 0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "nor\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  let isCodeGenOnly = 1 in
  def #32#
      : TileInstX1RRR
        <0x5, 0x1C,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "nor\t$rd, $rsa, $rsb",
         [(set (i32 CPU32Regs:$rd),
         (not (or CPU32Regs:$rsa, CPU32Regs:$rsb)))],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;
}

multiclass TileSHL {

  def #NAME#
      : TileInstX1RRR
        <0x5, 0x26,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "shl\t$rd, $rsa, $rsb",
         [(set (i64 CPURegs:$rd),
         (shl CPURegs:$rsa, CPURegs:$rsb))],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x4A,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "shl\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X1#
      : TileBundleX1RRR
        <0x5, 0x26,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "shl\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y0#
      : TileBundleY0RRR
        <0xB, 0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "shl\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y1#
      : TileBundleY1RRR
        <0xC, 0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "shl\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  let isCodeGenOnly = 1 in
  def #64_32#
      : TileInstX1RRR
        <0x5, 0x26,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPU32Regs:$rsb),
         "shl\t$rd, $rsa, $rsb",
         [(set (i64 CPURegs:$rd),
         (shl CPURegs:$rsa, CPU32Regs:$rsb))],
         IIC_LOGIC, FrmRRR, S_X0_X1>;
}

multiclass TileSHLX {

  def #NAME#
      : TileInstX1RRR
        <0x5, 0x25,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "shlx\t$rd, $rsa, $rsb",
         [(set (i32 CPU32Regs:$rd),
         (shl CPU32Regs:$rsa, CPU32Regs:$rsb))],
         IIC_LOGIC, FrmRRR, S_X0_X1>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x49,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "shlx\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC, FrmRRR, S_X0_X1>;

  def #0_X1#
      : TileBundleX1RRR
        <0x5, 0x25,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "shlx\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC, FrmRRR, S_X0_X1>;

}

multiclass TileSHLI {

  def #NAME#
      : TileInstX1Shift
        <0x6, 0x2,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$sht),
         "shli\t$rd, $rs, $sht",
         [(set (i64 CPURegs:$rd),
         (shl CPURegs:$rs, immZExt6:$sht))],
         IIC_LOGIC, FrmShift, S_X0_X1_Y0_Y1>;

  def #0_X0#
      : TileBundleX0Shift
        <0x6, 0x2,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$sht),
         "shli\t$rd, $rs, $sht",
         [],
         IIC_LOGIC, FrmShift, S_X0_X1_Y0_Y1>;

  def #0_X1#
      : TileBundleX1Shift
        <0x6, 0x2,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$sht),
         "shli\t$rd, $rs, $sht",
         [],
         IIC_LOGIC, FrmShift, S_X0_X1_Y0_Y1>;

  def #0_Y0#
      : TileBundleY0Shift
        <0xF, 0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$sht),
         "shli\t$rd, $rs, $sht",
         [],
         IIC_LOGIC, FrmShift, S_X0_X1_Y0_Y1>;

  def #0_Y1#
      : TileBundleY1Shift
        <0xE, 0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$sht),
         "shli\t$rd, $rs, $sht",
         [],
         IIC_LOGIC, FrmShift, S_X0_X1_Y0_Y1>;

  let isCodeGenOnly = 1 in
  def #64_32#
      : TileInstX1Shift
        <0x6, 0x2,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i32imm:$sht),
         "shli\t$rd, $rs, $sht",
         [(set (i64 CPURegs:$rd),
         (shl CPURegs:$rs, immZExt6_32:$sht))],
         IIC_LOGIC, FrmShift, S_X0_X1_Y0_Y1>;
}

multiclass TileSHLXI {

  def #NAME#
      : TileInstX1Shift
        <0x6, 0x3,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rs, i32imm:$sht),
         "shlxi\t$rd, $rs, $sht",
         [(set (i32 CPU32Regs:$rd),
         (shl CPU32Regs:$rs, immZExt5_32:$sht))],
         IIC_LOGIC, FrmShift, S_X0_X1>;

  def #0_X0#
      : TileBundleX0Shift
        <0x6, 0x3,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, i32imm:$sht),
         "shlxi\t$rd, $rsa, $sht",
         [],
         IIC_LOGIC, FrmShift, S_X0_X1>;

  def #0_X1#
      : TileBundleX1Shift
        <0x6, 0x3,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, i32imm:$sht),
         "shlxi\t$rd, $rsa, $sht",
         [],
         IIC_LOGIC, FrmShift, S_X0_X1>;

  let isCodeGenOnly = 1 in
  def #32_64#
      : TileInstX1Shift
        <0x6, 0x3,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rs, i64imm:$sht),
         "shlxi\t$rd, $rs, $sht",
         [(set (i32 CPU32Regs:$rd),
         (shl CPU32Regs:$rs, immZExt5:$sht))],
         IIC_LOGIC, FrmShift, S_X0_X1_Y0_Y1>;
}

multiclass TileSHRU {

  def #NAME#
      : TileInstX1RRR
        <0x5, 0x29,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "shru\t$rd, $rsa, $rsb",
         [(set (i64 CPURegs:$rd),
           (srl CPURegs:$rsa, CPURegs:$rsb))],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x4D,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "shru\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X1#
      : TileBundleX1RRR
        <0x5, 0x29,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "shru\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y0#
      : TileBundleY0RRR
        <0xB, 0x3,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "shru\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y1#
      : TileBundleY1RRR
        <0xC, 0x3,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "shru\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  let isCodeGenOnly = 1 in
  def #64_32#
      : TileInstX1RRR
        <0x5, 0x29,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPU32Regs:$rsb),
         "shru\t$rd, $rsa, $rsb",
         [(set (i64 CPURegs:$rd),
           (srl CPURegs:$rsa, CPU32Regs:$rsb))],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;
}

multiclass TileSHRUX {

  def #NAME#
      : TileInstX1RRR
        <0x5, 0x28,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "shrux\t$rd, $rsa, $rsb",
         [(set (i32 CPU32Regs:$rd),
           (srl CPU32Regs:$rsa, CPU32Regs:$rsb))],
         IIC_LOGIC, FrmRRR, S_X0_X1>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x4C,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "shrux\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC, FrmRRR, S_X0_X1>;

  def #0_X1#
      : TileBundleX1RRR
        <0x5, 0x28,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "shrux\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC, FrmRRR, S_X0_X1>;
}

multiclass TileSHRUI {

  def #NAME#
      : TileInstX1Shift
        <0x6, 0x5,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$sht),
         "shrui\t$rd, $rs, $sht",
         [(set (i64 CPURegs:$rd),
           (srl CPURegs:$rs, immZExt6:$sht))],
         IIC_LOGIC, FrmShift, S_X0_X1_Y0_Y1>;

  def #0_X0#
      : TileBundleX0Shift
        <0x6, 0x5,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$sht),
         "shrui\t$rd, $rs, $sht",
         [],
         IIC_LOGIC, FrmShift, S_X0_X1_Y0_Y1>;

  def #0_X1#
      : TileBundleX1Shift
        <0x6, 0x5,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$sht),
         "shrui\t$rd, $rs, $sht",
         [],
         IIC_LOGIC, FrmShift, S_X0_X1_Y0_Y1>;

  def #0_Y0#
      : TileBundleY0Shift
        <0xF, 0x3,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$sht),
         "shrui\t$rd, $rs, $sht",
         [],
         IIC_LOGIC, FrmShift, S_X0_X1_Y0_Y1>;

  def #0_Y1#
      : TileBundleY1Shift
        <0xE, 0x3,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$sht),
         "shrui\t$rd, $rs, $sht",
         [],
         IIC_LOGIC, FrmShift, S_X0_X1_Y0_Y1>;

  let isCodeGenOnly = 1 in {
  def #32_64#
      : TileInstX1Shift
        <0x6, 0x5,
         (outs CPU32Regs:$rd),
         (ins CPURegs:$rs, i64imm:$sht),
         "shrui\t$rd, $rs, $sht",
         [],
         IIC_LOGIC, FrmShift, S_X0_X1_Y0_Y1>;

  def #64_32#
      : TileInstX1Shift
        <0x6, 0x5,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i32imm:$sht),
         "shrui\t$rd, $rs, $sht",
         [(set (i64 CPURegs:$rd),
         (srl CPURegs:$rs, immZExt6_32:$sht))],
         IIC_LOGIC, FrmShift, S_X0_X1_Y0_Y1>;
  }
}

multiclass TileSHRUXI {

  def #NAME#
      : TileInstX1Shift
        <0x6, 0x6,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rs, i32imm:$sht),
         "shruxi\t$rd, $rs, $sht",
         [(set (i32 CPU32Regs:$rd),
           (srl CPU32Regs:$rs, immZExt6_32:$sht))],
         IIC_LOGIC, FrmShift, S_X0_X1>;

  def #0_X0#
      : TileBundleX0Shift
        <0x6, 0x6,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, i32imm:$sht),
         "shruxi\t$rd, $rsa, $sht",
         [],
         IIC_LOGIC, FrmShift, S_X0_X1>;

  def #0_X1#
      : TileBundleX1Shift
        <0x6, 0x6,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, i32imm:$sht),
         "shruxi\t$rd, $rsa, $sht",
         [],
         IIC_LOGIC, FrmShift, S_X0_X1>;
}

multiclass TileSHRS {

  def #NAME#
      : TileInstX1RRR
        <0x5, 0x27,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "shrs\t$rd, $rsa, $rsb",
         [(set (i64 CPURegs:$rd),
         (sra CPURegs:$rsa, CPURegs:$rsb))],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x4B,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "shrs\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X1#
      : TileBundleX1RRR
        <0x5, 0x27,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "shrs\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y0#
      : TileBundleY0RRR
        <0xB, 0x2,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "shrs\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y1#
      : TileBundleY1RRR
        <0xC, 0x2,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "shrs\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  let isCodeGenOnly = 1 in
  def #64_32#
      : TileInstX1RRR
        <0x5, 0x27,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPU32Regs:$rsb),
         "shrs\t$rd, $rsa, $rsb",
         [(set (i64 CPURegs:$rd),
           (sra CPURegs:$rsa, CPU32Regs:$rsb))],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;

  let isCodeGenOnly = 1 in
  def #32#
      : TileInstX1RRR
        <0x5, 0x27,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "shrs\t$rd, $rsa, $rsb",
         [(set (i32 CPU32Regs:$rd),
           (sra CPU32Regs:$rsa, CPU32Regs:$rsb))],
         IIC_LOGIC, FrmRRR, S_X0_X1_Y0_Y1>;
}

multiclass TileSHRSI {

  def #NAME#
      : TileInstX1Shift
        <0x6, 0x4,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$sht),
         "shrsi\t$rd, $rs, $sht",
         [(set (i64 CPURegs:$rd),
           (sra CPURegs:$rs, immZExt6:$sht))],
         IIC_LOGIC, FrmShift, S_X0_X1_Y0_Y1>;

  def #0_X0#
      : TileBundleX0Shift
        <0x6, 0x4,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$sht),
         "shrsi\t$rd, $rs, $sht",
         [],
         IIC_LOGIC, FrmShift, S_X0_X1_Y0_Y1>;

  def #0_X1#
      : TileBundleX1Shift
        <0x6, 0x4,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$sht),
         "shrsi\t$rd, $rs, $sht",
         [],
         IIC_LOGIC, FrmShift, S_X0_X1_Y0_Y1>;

  def #0_Y0#
      : TileBundleY0Shift
        <0xF, 0x2,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$sht),
         "shrsi\t$rd, $rs, $sht",
         [],
         IIC_LOGIC, FrmShift, S_X0_X1_Y0_Y1>;

  def #0_Y1#
      : TileBundleY1Shift
        <0xE, 0x2,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$sht),
         "shrsi\t$rd, $rs, $sht",
         [],
         IIC_LOGIC, FrmShift, S_X0_X1_Y0_Y1>;

  let isCodeGenOnly = 1 in {
  def #64_32#
      : TileInstX1Shift
        <0x6, 0x4,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i32imm:$sht),
         "shrsi\t$rd, $rs, $sht",
         [(set (i64 CPURegs:$rd),
         (sra CPURegs:$rs, immZExt6_32:$sht))],
         IIC_LOGIC, FrmShift, S_X0_X1_Y0_Y1>;

  def #32#
      : TileInstX1Shift
        <0x6, 0x4,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rs, i32imm:$sht),
         "shrsi\t$rd, $rs, $sht",
         [(set (i32 CPU32Regs:$rd),
         (sra CPU32Regs:$rs, immZExt6_32:$sht))],
         IIC_LOGIC, FrmShift, S_X0_X1_Y0_Y1>;

  def #32_64#
      : TileInstX1Shift
        <0x6, 0x4,
         (outs CPU32Regs:$rd),
         (ins CPURegs:$rs, i64imm:$sht),
         "shrsi\t$rd, $rs, $sht",
         [],
         IIC_LOGIC, FrmShift, S_X0_X1_Y0_Y1>;
  }
}

multiclass TileMOVEI {

  def #NAME#
      : TileMOVEIX1
        <0x3, 0x1,
         (outs CPURegs:$rd),
         (ins simm8_64:$imm8),
         "movei\t$rd, $imm8",
         [(set (i64 CPURegs:$rd), immSExt8:$imm8)],
         IIC_ALU, FrmImm8, S_X0_X1_Y0_Y1>;

  def #0_X0#
      : TileBundleX0MOVEI
        <0x4, 0x1,
         (outs CPURegs:$rd),
         (ins simm8_64:$imm8),
         "movei\t$rd, $imm8",
         [],
         IIC_ALU, FrmImm8, S_X0_X1_Y0_Y1>;

  def #0_X1#
      : TileBundleX1MOVEI
        <0x3, 0x1,
         (outs CPURegs:$rd),
         (ins simm8_64:$imm8),
         "movei\t$rd, $imm8",
         [],
         IIC_ALU, FrmImm8, S_X0_X1_Y0_Y1>;

  def #0_Y0#
      : TileBundleY0MOVEI
        <0x0,
         (outs CPURegs:$rd),
         (ins simm8_64:$imm8),
         "movei\t$rd, $imm8",
         [],
         IIC_ALU, FrmImm8, S_X0_X1_Y0_Y1>;

  def #0_Y1#
      : TileBundleY1MOVEI
        <0x1,
         (outs CPURegs:$rd),
         (ins simm8_64:$imm8),
         "movei\t$rd, $imm8",
         [],
         IIC_ALU, FrmImm8, S_X0_X1_Y0_Y1>;

  let isCodeGenOnly = 1 in
  def #32#
      : TileMOVEIX1
        <0x3, 0x1,
         (outs CPU32Regs:$rd),
         (ins simm8_32:$imm8),
         "movei\t$rd, $imm8",
         [(set (i32 CPU32Regs:$rd), immSExt8:$imm8)],
         IIC_ALU, FrmImm8, S_X0_X1_Y0_Y1>;
}

multiclass TileMOVELI {

  def #NAME#
      : TileMOVELIX1
        <0x0,
         (outs CPURegs:$rd), (ins simm16_64:$imm16),
         "moveli\t$rd, $imm16",
         [(set (i64 CPURegs:$rd), immSExt16:$imm16)],
         IIC_ALU, FrmImm16, S_X0_X1>;

  def #0_X0#
      : TileBundleX0MOVELI
        <0x1,
         (outs CPURegs:$rd), (ins simm16_64:$imm16),
         "moveli\t$rd, $imm16",
         [],
         IIC_ALU, FrmImm16, S_X0_X1>;

  def #0_X1#
      : TileBundleX1MOVELI
        <0x0,
         (outs CPURegs:$rd), (ins simm16_64:$imm16),
         "moveli\t$rd, $imm16",
         [],
         IIC_ALU, FrmImm16, S_X0_X1>;

  let isCodeGenOnly = 1 in
  def #32#
      : TileMOVELIX1
        <0x0,
         (outs CPU32Regs:$rd),
         (ins simm16_32:$imm16),
         "moveli\t$rd, $imm16",
         [(set (i32 CPU32Regs:$rd), immSExt16:$imm16)],
         IIC_ALU, FrmImm16, S_X0_X1>;
}

multiclass TileSHL16INSLI {

  def #NAME#
      : TileInstX1Imm16
        <0x7,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, simm16_64:$imm16),
         "shl16insli\t$rd, $rs, $imm16",
         [(set (i64 CPURegs:$rd),
           (add (shl CPURegs:$rs, (i64 16)), immSExt16:$imm16))],
         IIC_ALU, FrmImm16, S_X0_X1>;

  def #0_X0#
      : TileBundleX0Imm16
        <0x7,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, simm16_64:$imm16),
         "shl16insli\t$rd, $rs, $imm16",
         [],
         IIC_ALU, FrmImm16, S_X0_X1>;

  def #0_X1#
      : TileBundleX1Imm16
        <0x7,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, simm16_64:$imm16),
         "shl16insli\t$rd, $rs, $imm16",
         [],
         IIC_ALU, FrmImm16, S_X0_X1>;

  let isCodeGenOnly = 1 in
  def #32#
      : TileInstX1Imm16
        <0x7,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rs, simm16_32:$imm16),
         "shl16insli\t$rd, $rs, $imm16",
         [(set (i32 CPU32Regs:$rd),
           (add (shl CPU32Regs:$rs, (i64 16)), immSExt16:$imm16))],
         IIC_ALU, FrmImm16, S_X0_X1>;
}

multiclass TileCMPLTSI {

  def #NAME#
      : TileInstX1Imm8
        <0x3, 0x5,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "cmpltsi\t$rd, $rs, $imm8",
         [(set (i64 CPURegs:$rd), (setlt CPURegs:$rs, immSExt8:$imm8))],
         IIC_CMP, FrmImm8, S_X0_X1_Y0_Y1>;

  def #0_X0#
      : TileBundleX0Imm8
        <0x4, 0x5,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "cmpltsi\t$rd, $rs, $imm8",
         [],
         IIC_CMP, FrmImm8, S_X0_X1_Y0_Y1>;

  def #0_X1#
      : TileBundleX1Imm8
        <0x3, 0x5,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "cmpltsi\t$rd, $rs, $imm8",
         [],
         IIC_CMP, FrmImm8, S_X0_X1_Y0_Y1>;

  def #0_Y0#
      : TileBundleY0Imm8
        <0x4,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "cmpltsi\t$rd, $rs, $imm8",
         [],
         IIC_CMP, FrmImm8, S_X0_X1_Y0_Y1>;

  def #0_Y1#
      : TileBundleY1Imm8
        <0x5,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "cmpltsi\t$rd, $rs, $imm8",
         [],
         IIC_CMP, FrmImm8, S_X0_X1_Y0_Y1>;

  let isCodeGenOnly = 1 in
  def #32_64#
      : TileInstX1Imm8
        <0x3, 0x5,
         (outs CPU32Regs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "cmpltsi\t$rd, $rs, $imm8",
         [(set (i32 CPU32Regs:$rd), (setlt CPURegs:$rs, immSExt8:$imm8))],
         IIC_CMP, FrmImm8, S_X0_X1_Y0_Y1>;
}

multiclass TileCMPLTUI {

  def #NAME#
      : TileInstX1Imm8
        <0x3, 0x6,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "cmpltui\t$rd, $rs, $imm8",
         [(set (i64 CPURegs:$rd), (setult CPURegs:$rs, immSExt8:$imm8))],
         IIC_CMP, FrmImm8, S_X0_X1>;
  
  def #0_X0#
      : TileBundleX0Imm8
        <0x4, 0x6,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "cmpltui\t$rd, $rs, $imm8",
         [],
         IIC_CMP, FrmImm8, S_X0_X1>;

  def #0_X1#
      : TileBundleX1Imm8
        <0x3, 0x6,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "cmpltui\t$rd, $rs, $imm8",
         [],
         IIC_CMP, FrmImm8, S_X0_X1>;

  let isCodeGenOnly = 1 in
  def #32_64#
      : TileInstX1Imm8
        <0x3, 0x6,
         (outs CPU32Regs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "cmpltui\t$rd, $rs, $imm8",
         [(set (i32 CPU32Regs:$rd), (setult CPURegs:$rs, immSExt8:$imm8))],
         IIC_CMP, FrmImm8, S_X0_X1>;
}

multiclass TileCMPLTS {

  def #NAME#
      : TileInstX1RRR
        <0x5, 0xA,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmplts\t$rd, $rsa, $rsb",
         [(set (i64 CPURegs:$rd), (setlt (i64 CPURegs:$rsa), CPURegs:$rsb))],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0xA,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmplts\t$rd, $rsa, $rsb",
         [],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X1#
      : TileBundleX1RRR
        <0x5, 0xA,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmplts\t$rd, $rsa, $rsb",
         [],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y0#
      : TileBundleY0RRR
        <0x7, 0x2,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmplts\t$rd, $rsa, $rsb",
         [],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y1#
      : TileBundleY1RRR
        <0x8, 0x2,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmplts\t$rd, $rsa, $rsb",
         [],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  let isCodeGenOnly = 1 in
  def #32_64#
      : TileInstX1RRR
        <0x5, 0xA,
         (outs CPU32Regs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmplts\t$rd, $rsa, $rsb",
         [(set (i32 CPU32Regs:$rd), (setlt (i64 CPURegs:$rsa), CPURegs:$rsb))],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;
}

multiclass TileCMPLTU {

  def #NAME#
      : TileInstX1RRR
        <0x5, 0xB,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmpltu\t$rd, $rsa, $rsb",
         [(set (i64 CPURegs:$rd), (setult (i64 CPURegs:$rsa), CPURegs:$rsb))],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0xB,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmpltu\t$rd, $rsa, $rsb",
         [],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X1#
      : TileBundleX1RRR
        <0x5, 0xB,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmpltu\t$rd, $rsa, $rsb",
         [],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y0#
      : TileBundleY0RRR
        <0x7, 0x3,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmpltu\t$rd, $rsa, $rsb",
         [],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y1#
      : TileBundleY1RRR
        <0x7, 0x3,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmpltu\t$rd, $rsa, $rsb",
         [],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  let isCodeGenOnly = 1 in
  def #32#
      : TileInstX1RRR
        <0x5, 0xB,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "cmpltu\t$rd, $rsa, $rsb",
         [(set (i32 CPU32Regs:$rd), (setult (i32 CPU32Regs:$rsa), CPU32Regs:$rsb))],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  let isCodeGenOnly = 1 in
  def #32_64#
      : TileInstX1RRR
        <0x5, 0xB,
         (outs CPU32Regs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmpltu\t$rd, $rsa, $rsb",
         [(set (i32 CPU32Regs:$rd), (setult (i64 CPURegs:$rsa), CPURegs:$rsb))],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;
}

multiclass TileCMPLES {

  def #NAME#
      : TileInstX1RRR
        <0x5, 0x8,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmples\t$rd, $rsa, $rsb",
         [(set (i64 CPURegs:$rd), (setle (i64 CPURegs:$rsa), CPURegs:$rsb))],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x8,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmples\t$rd, $rsa, $rsb",
         [],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X1#
      : TileBundleX1RRR
        <0x5, 0x8,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmples\t$rd, $rsa, $rsb",
         [],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y0#
      : TileBundleY0RRR
        <0x7, 0x0,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmples\t$rd, $rsa, $rsb",
         [],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y1#
      : TileBundleY1RRR
        <0x8, 0x0,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmples\t$rd, $rsa, $rsb",
         [],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  let isCodeGenOnly = 1 in
  def #32_64#
      : TileInstX1RRR
        <0x5, 0x8,
         (outs CPU32Regs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmples\t$rd, $rsa, $rsb",
         [(set (i32 CPU32Regs:$rd), (setle (i64 CPURegs:$rsa), CPURegs:$rsb))],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;
}

multiclass TileCMPLEU {

  def #NAME#
      : TileInstX1RRR
        <0x5, 0x9,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmpleu\t$rd, $rsa, $rsb",
         [(set (i64 CPURegs:$rd), (setule (i64 CPURegs:$rsa), CPURegs:$rsb))],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x9,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmpleu\t$rd, $rsa, $rsb",
         [],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X1#
      : TileBundleX1RRR
        <0x5, 0x9,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmpleu\t$rd, $rsa, $rsb",
         [],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y0#
      : TileBundleY0RRR
        <0x7, 0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmpleu\t$rd, $rsa, $rsb",
         [],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y1#
      : TileBundleY1RRR
        <0x8, 0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmpleu\t$rd, $rsa, $rsb",
         [],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  let isCodeGenOnly = 1 in
  def #32#
      : TileInstX1RRR
        <0x5, 0x9,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "cmpleu\t$rd, $rsa, $rsb",
         [(set (i32 CPU32Regs:$rd), (setule (i32 CPU32Regs:$rsa), CPU32Regs:$rsb))],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  let isCodeGenOnly = 1 in
  def #32_64#
      : TileInstX1RRR
        <0x5, 0x9,
         (outs CPU32Regs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmpleu\t$rd, $rsa, $rsb",
         [(set (i32 CPU32Regs:$rd), (setule (i64 CPURegs:$rsa), CPURegs:$rsb))],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;
}

multiclass TileCMPEQ {

  def #NAME#
      : TileInstX1RRR
        <0x5, 0x5,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmpeq\t$rd, $rsa, $rsb",
         [(set (i64 CPURegs:$rd), (seteq (i64 CPURegs:$rsa), CPURegs:$rsb))],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x7,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmpeq\t$rd, $rsa, $rsb",
         [],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X1#
      : TileBundleX1RRR
        <0x5, 0x5,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmpeq\t$rd, $rsa, $rsb",
         [],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y0#
      : TileBundleY0RRR
        <0x8, 0x0,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmpeq\t$rd, $rsa, $rsb",
         [],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y1#
      : TileBundleY1RRR
        <0x9, 0x2,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmpeq\t$rd, $rsa, $rsb",
         [],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  let isCodeGenOnly = 1 in
  def #32#
      : TileInstX1RRR
        <0x5, 0x5,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "cmpeq\t$rd, $rsa, $rsb",
         [(set (i32 CPU32Regs:$rd), (seteq (i32 CPU32Regs:$rsa), CPU32Regs:$rsb))],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  let isCodeGenOnly = 1 in
  def #32_64#
      : TileInstX1RRR
        <0x5, 0x5,
         (outs CPU32Regs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmpeq\t$rd, $rsa, $rsb",
         [(set (i32 CPU32Regs:$rd), (seteq (i64 CPURegs:$rsa), CPURegs:$rsb))],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;
}

multiclass TileCMPNE {

  def #NAME#
      : TileInstX1RRR
        <0x5, 0xC,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmpne\t$rd, $rsa, $rsb",
         [(set (i64 CPURegs:$rd), (setne (i64 CPURegs:$rsa), CPURegs:$rsb))],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0xC,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmpne\t$rd, $rsa, $rsb",
         [],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X1#
      : TileBundleX1RRR
        <0x5, 0xC,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmpne\t$rd, $rsa, $rsb",
         [],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y0#
      : TileBundleY0RRR
        <0x8, 0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmpne\t$rd, $rsa, $rsb",
         [],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y1#
      : TileBundleY1RRR
        <0x9, 0x3,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmpne\t$rd, $rsa, $rsb",
         [],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  let isCodeGenOnly = 1 in
  def #32#
      : TileInstX1RRR
        <0x5, 0xC,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "cmpne\t$rd, $rsa, $rsb",
         [(set (i32 CPU32Regs:$rd), (setne (i32 CPU32Regs:$rsa), CPU32Regs:$rsb))],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;

  let isCodeGenOnly = 1 in
  def #32_64#
      : TileInstX1RRR
        <0x5, 0xC,
         (outs CPU32Regs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "cmpne\t$rd, $rsa, $rsb",
         [(set (i32 CPU32Regs:$rd), (setne (i64 CPURegs:$rsa), CPURegs:$rsb))],
         IIC_CMP, FrmRRR, S_X0_X1_Y0_Y1>;
}

multiclass TileCMPEQI {

  def #NAME#
      : TileInstX1Imm8
        <0x3, 0x4,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "cmpeqi\t$rd, $rs, $imm8",
         [(set (i64 CPURegs:$rd), (seteq CPURegs:$rs, immSExt8:$imm8))],
         IIC_CMP, FrmImm8, S_X0_X1_Y0_Y1>;

  def #0_X0#
      : TileBundleX0Imm8
        <0x4, 0x4,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "cmpeqi\t$rd, $rs, $imm8",
         [],
         IIC_CMP, FrmImm8, S_X0_X1_Y0_Y1>;

  def #0_X1#
      : TileBundleX1Imm8
        <0x3, 0x4,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "cmpeqi\t$rd, $rs, $imm8",
         [],
         IIC_CMP, FrmImm8, S_X0_X1_Y0_Y1>;

  def #0_Y0#
      : TileBundleY0Imm8
        <0x3,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "cmpeqi\t$rd, $rs, $imm8",
         [],
         IIC_CMP, FrmImm8, S_X0_X1_Y0_Y1>;

  def #0_Y1#
      : TileBundleY1Imm8
        <0x4,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "cmpeqi\t$rd, $rs, $imm8",
         [],
         IIC_CMP, FrmImm8, S_X0_X1_Y0_Y1>;

  let isCodeGenOnly = 1 in
  def #32_64#
      : TileInstX1Imm8
        <0x3, 0x4,
         (outs CPU32Regs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "cmpeqi\t$rd, $rs, $imm8",
         [(set (i32 CPU32Regs:$rd), (seteq CPURegs:$rs, immSExt8:$imm8))],
         IIC_CMP, FrmImm8, S_X0_X1_Y0_Y1>;
}

let isBranch = 1, isTerminator = 1 in
multiclass TileBNEZ {

  def #NAME#
      : TileInstX1Branch
        <0x2, 0x1F,
         (outs),
         (ins CPURegs:$rs, brtarget:$br_target),
         "bnez\t$rs, $br_target",
         [(brcond (i64 (setne CPURegs:$rs, 0)), bb:$br_target)],
         IIC_CTL, FrmBr, S_X1>;

  def #0_X1#
      : TileBundleX1Branch
        <0x2, 0x1F,
         (outs),
         (ins CPURegs:$rs, brtarget:$br_target),
         "bnez\t$rs, $br_target",
         [],
         IIC_CTL, FrmBr, S_X1>;

  let isCodeGenOnly = 1 in
  def #32#
      : TileInstX1Branch
        <0x2, 0x1F,
         (outs),
         (ins CPU32Regs:$rs, brtarget:$br_target),
         "bnez\t$rs, $br_target",
         [(brcond (i32 (setne CPU32Regs:$rs, 0)), bb:$br_target)],
         IIC_CTL, FrmBr, S_X1>;
}

let isBranch = 1, isTerminator = 1 in
multiclass TileBEQZ {

  def #NAME#
      : TileInstX1Branch
        <0x2, 0x11,
         (outs),
         (ins CPURegs:$rs, brtarget:$br_target),
         "beqz\t$rs, $br_target",
         [(brcond (i64 (seteq CPURegs:$rs, 0)), bb:$br_target)],
         IIC_CTL, FrmBr, S_X1>;

  def #0_X1#
      : TileBundleX1Branch
        <0x2, 0x11,
         (outs),
         (ins CPURegs:$rs, brtarget:$br_target),
         "beqz\t$rs, $br_target",
         [],
         IIC_CTL, FrmBr, S_X1>;

  let isCodeGenOnly = 1 in
  def #32#
      : TileInstX1Branch
        <0x2, 0x11,
         (outs),
         (ins CPU32Regs:$rs, brtarget:$br_target),
         "beqz\t$rs, $br_target",
         [(brcond (i32 (seteq CPU32Regs:$rs, 0)), bb:$br_target)],
         IIC_CTL, FrmBr, S_X1>;
}

let isBranch = 1, isTerminator = 1 in
multiclass TileBLEZ {

  def #NAME#
      : TileInstX1Branch
        <0x2, 0x1B,
         (outs),
         (ins CPURegs:$rs, brtarget:$br_target),
         "blez\t$rs, $br_target",
         [(brcond (i64 (setle CPURegs:$rs, 0)), bb:$br_target)],
         IIC_CTL, FrmBr, S_X1>;

  def #0_X1#
      : TileBundleX1Branch
        <0x2, 0x1B,
         (outs),
         (ins CPURegs:$rs, brtarget:$br_target),
         "blez\t$rs, $br_target",
         [],
         IIC_CTL, FrmBr, S_X1>;

  let isCodeGenOnly = 1 in
  def #32#
      : TileInstX1Branch
        <0x2, 0x1B,
         (outs),
         (ins CPU32Regs:$rs, brtarget:$br_target),
         "blez\t$rs, $br_target",
         [(brcond (i32 (setle CPU32Regs:$rs, 0)), bb:$br_target)],
         IIC_CTL, FrmBr, S_X1>;
}

let isBranch = 1, isTerminator = 1 in
multiclass TileBLTZ {

  def #NAME#
      : TileInstX1Branch
        <0x2, 0x1d,
         (outs),
         (ins CPURegs:$rs, brtarget:$br_target),
         "bltz\t$rs, $br_target",
         [(brcond (i64 (setlt CPURegs:$rs, 0)), bb:$br_target)],
         IIC_CTL, FrmBr, S_X1>;

  def #0_X1#
      : TileBundleX1Branch
        <0x2, 0x1d,
         (outs),
         (ins CPURegs:$rs, brtarget:$br_target),
         "bltz\t$rs, $br_target",
         [],
         IIC_CTL, FrmBr, S_X1>;

  let isCodeGenOnly = 1 in
  def #32#
      : TileInstX1Branch
        <0x2, 0x1d,
         (outs),
         (ins CPU32Regs:$rs, brtarget:$br_target),
         "bltz\t$rs, $br_target",
         [(brcond (i32 (setlt CPU32Regs:$rs, 0)), bb:$br_target)],
         IIC_CTL, FrmBr, S_X1>;
}

let isBranch = 1, isTerminator = 1 in
multiclass TileBGEZ {

  def #NAME#
      : TileInstX1Branch
        <0x2, 0x13,
         (outs),
         (ins CPURegs:$rs, brtarget:$br_target),
         "bgez\t$rs, $br_target",
         [(brcond (i64 (setge CPURegs:$rs, 0)), bb:$br_target)],
         IIC_CTL, FrmBr, S_X1>;

  def #0_X1#
      : TileBundleX1Branch
        <0x2, 0x13,
         (outs),
         (ins CPURegs:$rs, brtarget:$br_target),
         "bgez\t$rs, $br_target",
         [],
         IIC_CTL, FrmBr, S_X1>;

  let isCodeGenOnly = 1 in
  def #32#
      : TileInstX1Branch
        <0x2, 0x13,
         (outs),
         (ins CPU32Regs:$rs, brtarget:$br_target),
         "bgez\t$rs, $br_target",
         [(brcond (i32 (setge CPU32Regs:$rs, 0)), bb:$br_target)],
         IIC_CTL, FrmBr, S_X1>;
}

let isBranch = 1, isTerminator = 1 in
multiclass TileBGTZ {

  def #NAME#
      : TileInstX1Branch
        <0x2, 0x15,
         (outs),
         (ins CPURegs:$rs, brtarget:$br_target),
         "bgtz\t$rs, $br_target",
         [(brcond (i64 (setgt CPURegs:$rs, 0)), bb:$br_target)],
         IIC_CTL, FrmBr, S_X1>;

  def #0_X1#
      : TileBundleX1Branch
        <0x2, 0x15,
         (outs),
         (ins CPURegs:$rs, brtarget:$br_target),
         "bgtz\t$rs, $br_target",
         [],
         IIC_CTL, FrmBr, S_X1>;

  let isCodeGenOnly = 1 in
  def #32#
      : TileInstX1Branch
        <0x2, 0x15,
         (outs),
         (ins CPU32Regs:$rs, brtarget:$br_target),
         "bgtz\t$rs, $br_target",
         [(brcond (i32 (setgt CPU32Regs:$rs, 0)), bb:$br_target)],
         IIC_CTL, FrmBr, S_X1>;
}

let Constraints = "$rf =\t$rd" in
multiclass TileCMOVNEZ {

  def #NAME#
      : TileInstX0RRR
        <0x5, 0x6,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb, CPURegs:$rf),
         "cmovnez\t$rd, $rsa, $rsb",
         [(set (i64 CPURegs:$rd), (select (i64 CPURegs:$rsa), (i64 CPURegs:$rsb), (i64 CPURegs:$rf)))],
         IIC_LOGIC_P0, FrmRRR, S_X0_Y0>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x6,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb, CPURegs:$rf),
         "cmovnez\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC_P0, FrmRRR, S_X0_Y0>;

  def #0_Y0#
      : TileBundleY0RRR
        <0x9, 0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb, CPURegs:$rf),
         "cmovnez\t$rd, $rsa, $rsb",
         [],
         IIC_LOGIC_P0, FrmRRR, S_X0_Y0>;

  let isCodeGenOnly = 1 in {
  def #32# 
      : TileInstX0RRR
        <0x5, 0x6,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb, CPU32Regs:$rf),
         "cmovnez\t$rd, $rsa, $rsb",
         [(set (i32 CPU32Regs:$rd),
           (select (i32 CPU32Regs:$rsa),
             (i32 CPU32Regs:$rsb), (i32 CPU32Regs:$rf)))],
         IIC_LOGIC_P0, FrmRRR, S_X0_Y0>;

  def #64_32# 
      : TileInstX0RRR
        <0x5, 0x6,
         (outs CPU32Regs:$rd),
         (ins CPURegs:$rsa, CPU32Regs:$rsb, CPU32Regs:$rf),
         "cmovnez\t$rd, $rsa, $rsb",
         [(set (i32 CPU32Regs:$rd),
           (select (i64 CPURegs:$rsa),
             (i32 CPU32Regs:$rsb), (i32 CPU32Regs:$rf)))],
         IIC_LOGIC_P0, FrmRRR, S_X0_Y0>;

  def #C32#
      : TileInstX0RRR
        <0x5, 0x6,
         (outs CPURegs:$rd),
         (ins CPU32Regs:$rsa, CPURegs:$rsb, CPURegs:$rf),
         "cmovnez\t$rd, $rsa, $rsb",
         [(set (i64 CPURegs:$rd),
           (select (i32 CPU32Regs:$rsa),
            (i64 CPURegs:$rsb), (i64 CPURegs:$rf)))],
         IIC_LOGIC_P0, FrmRRR, S_X0_Y0>;

  def #F32# 
      : TileInstX0RRR
        <0x5, 0x6,
         (outs CPU32Regs:$rd),
         (ins CPURegs:$rsa, CPU32Regs:$rsb, CPU32Regs:$rf),
         "cmovnez\t$rd, $rsa, $rsb",
         [(set (f32 CPU32Regs:$rd),
           (select (i64 CPURegs:$rsa),
            (f32 CPU32Regs:$rsb), (f32 CPU32Regs:$rf)))],
         IIC_LOGIC_P0, FrmRRR, S_X0_Y0>;

  def #F32_32# 
      : TileInstX0RRR
        <0x5, 0x6,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb, CPU32Regs:$rf),
         "cmovnez\t$rd, $rsa, $rsb",
         [(set (f32 CPU32Regs:$rd),
           (select (i32 CPU32Regs:$rsa),
            (f32 CPU32Regs:$rsb), (f32 CPU32Regs:$rf)))],
         IIC_LOGIC_P0, FrmRRR, S_X0_Y0>;

  def #F64#
      : TileInstX0RRR
        <0x5, 0x6,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb, CPURegs:$rf),
         "cmovnez\t$rd, $rsa, $rsb",
         [(set (f64 CPURegs:$rd),
           (select (i64 CPURegs:$rsa),
            (f64 CPURegs:$rsb), (f64 CPURegs:$rf)))],
         IIC_LOGIC_P0, FrmRRR, S_X0_Y0>;

  def #F64_32#
      : TileInstX0RRR
        <0x5, 0x6,
         (outs CPURegs:$rd),
         (ins CPU32Regs:$rsa, CPURegs:$rsb, CPURegs:$rf),
         "cmovnez\t$rd, $rsa, $rsb",
         [(set (f64 CPURegs:$rd),
           (select (i32 CPU32Regs:$rsa),
            (f64 CPURegs:$rsb), (f64 CPURegs:$rf)))],
         IIC_LOGIC_P0, FrmRRR, S_X0_Y0>;
  }
}

// Bit manipulationn instructions.
multiclass TileCLZ {

  def #NAME#
      : TileInstX0Unary
        <0x5, 0x52, 0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs),
         "clz\t$rd, $rs",
         [(set (i64 CPURegs:$rd), (ctlz CPURegs:$rs))],
         IIC_BIT_P0, FrmUnary, S_X0_Y0>;

  def #0_X0#
      : TileBundleX0Unary
        <0x5, 0x52, 0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs),
         "clz\t$rd, $rs",
         [],
         IIC_BIT_P0, FrmUnary, S_X0_Y0>;

  def #0_Y0#
      : TileBundleY0Unary
        <0x6, 0x3, 0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs),
         "clz\t$rd, $rs",
         [],
         IIC_BIT_P0, FrmUnary, S_X0_Y0>;

  // FIXME: multi insts.
  let isCodeGenOnly = 1, isSoloInst = 1 in
  def #32#
      : TileInstX0Unary
        <0x5, 0x52, 0x1,
         (outs CPU32Regs:$rd),
          (ins CPU32Regs:$rs),
          "shli\t$rd, $rs, 32\n\tclz\t$rd, $rd",
          [(set (i32 CPU32Regs:$rd), (ctlz CPU32Regs:$rs))],
          IIC_BIT_P0, FrmUnary, S_X0_Y0>;
}

multiclass TileCTZ {

  def #NAME#
      : TileInstX0Unary
        <0x5, 0x52, 0x2,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs),
         "ctz\t$rd, $rs",
         [(set (i64 CPURegs:$rd), (cttz CPURegs:$rs))],
         IIC_BIT_P0, FrmUnary, S_X0_Y0>;

  def #0_X0#
      : TileBundleX0Unary
        <0x5, 0x52, 0x2,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs),
         "ctz\t$rd, $rs",
         [],
         IIC_BIT_P0, FrmUnary, S_X0_Y0>;

  def #0_Y0#
      : TileBundleY0Unary
        <0x6, 0x3, 0x2,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs),
         "ctz\t$rd, $rs",
         [],
         IIC_BIT_P0, FrmUnary, S_X0_Y0>;

  let isCodeGenOnly = 1 in
  def #32#
      : TileInstX0Unary
        <0x5, 0x52, 0x2,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rs),
         "ctz\t$rd, $rs",
         [(set (i32 CPU32Regs:$rd), (cttz CPU32Regs:$rs))],
         IIC_BIT_P0, FrmUnary, S_X0_Y0>;
}

multiclass TilePCNT {

  def #NAME#
      : TileInstX0Unary
        <0x5, 0x52, 0x6,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs),
         "pcnt\t$rd, $rs",
         [(set (i64 CPURegs:$rd), (ctpop CPURegs:$rs))],
         IIC_BIT_P0, FrmUnary, S_X0_Y0>;

  def #0_X0#
      : TileBundleX0Unary
        <0x5, 0x52, 0x6,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs),
         "pcnt\t$rd, $rs",
         [],
         IIC_BIT_P0, FrmUnary, S_X0_Y0>;

  def #0_Y0#
      : TileBundleY0Unary
        <0x6, 0x3, 0x6,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs),
         "pcnt\t$rd, $rs",
         [],
         IIC_BIT_P0, FrmUnary, S_X0_Y0>;
}

multiclass TileREVBYTES {
  def #NAME#
      : TileInstX0Unary
        <0x5, 0x52, 0x8,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs),
         "revbytes\t$rd, $rs",
         [(set (i64 CPURegs:$rd), (bswap CPURegs:$rs))],
         IIC_BIT_P0, FrmUnary, S_X0_Y0>;

  def #0_X0#
      : TileBundleX0Unary
        <0x5, 0x52, 0x8,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs),
         "revbytes\t$rd, $rs",
         [],
         IIC_BIT_P0, FrmUnary, S_X0_Y0>;

  def #0_Y0#
      : TileBundleY0Unary
        <0x6, 0x3, 0x8,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs),
         "revbytes\t$rd, $rs",
         [],
         IIC_BIT_P0, FrmUnary, S_X0_Y0>;

  //FIXME: multi insts
  let isCodeGenOnly = 1, isSoloInst = 1 in
  def #32#
      : TileInstX0Unary
        <0x5, 0x52, 0x8,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rs),
         "revbytes\t$rd, $rs\n\tshrui\t$rd, $rd, 32",
         [(set (i32 CPU32Regs:$rd), (bswap CPU32Regs:$rs))],
         IIC_BIT_P0, FrmUnary, S_X0_Y0>;
}

multiclass TileROTL {

  def #NAME#
      : TileInstX1RRR
        <0x5, 0x1E,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "rotl\t$rd, $rsa, $rsb",
         [(set (i64 CPURegs:$rd),
           (rotl CPURegs:$rsa, CPURegs:$rsb))],
         IIC_BIT, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x42,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "rotl\t$rd, $rsa, $rsb",
         [],
         IIC_BIT, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X1#
      : TileBundleX1RRR
        <0x5, 0x1E,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "rotl\t$rd, $rsa, $rsb",
         [],
         IIC_BIT, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y0#
      : TileBundleY0RRR
        <0xB, 0x0,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "rotl\t$rd, $rsa, $rsb",
         [],
         IIC_BIT, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y1#
      : TileBundleY1RRR
        <0xC, 0x0,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "rotl\t$rd, $rsa, $rsb",
         [],
         IIC_BIT, FrmRRR, S_X0_X1_Y0_Y1>;

  let isCodeGenOnly = 1 in {
  def #32#
      : TileInstX1RRR
        <0x5, 0x1E,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPU32Regs:$rsb),
         "rotl\t$rd, $rsa, $rsb",
         [(set (i64 CPURegs:$rd),
           (rotl CPURegs:$rsa, CPU32Regs:$rsb))],
         IIC_BIT, FrmRRR, S_X0_X1_Y0_Y1>;
  }
}

multiclass TileROTLI {

  def #NAME#
      : TileInstX1Shift
        <0x6, 0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$sht),
         "rotli\t$rd, $rs, $sht",
         [(set (i64 CPURegs:$rd),
          (rotl CPURegs:$rs, immZExt6:$sht))],
         IIC_BIT, FrmShift, S_X0_X1_Y0_Y1>;

  def #0_X0#
      : TileBundleX0Shift
        <0x6, 0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$sht),
         "rotli\t$rd, $rs, $sht",
         [],
         IIC_BIT, FrmShift, S_X0_X1_Y0_Y1>;

  def #0_X1#
      : TileBundleX1Shift
        <0x6, 0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$sht),
         "rotli\t$rd, $rs, $sht",
         [],
         IIC_BIT, FrmShift, S_X0_X1_Y0_Y1>;

  def #0_Y0#
      : TileBundleY0Shift
        <0xF, 0x0,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$sht),
         "rotli\t$rd, $rs, $sht",
         [],
         IIC_BIT, FrmShift, S_X0_X1_Y0_Y1>;

  def #0_Y1#
      : TileBundleY1Shift
        <0xE, 0x0,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$sht),
         "rotli\t$rd, $rs, $sht",
         [],
         IIC_BIT, FrmShift, S_X0_X1_Y0_Y1>;

  let isCodeGenOnly = 1 in {
  def #32#
      : TileInstX1Shift
        <0x6, 0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i32imm:$sht),
         "rotli\t$rd, $rs, $sht",
         [(set (i64 CPURegs:$rd),
          (rotl CPURegs:$rs, immZExt6_32:$sht))],
         IIC_BIT, FrmShift, S_X0_X1_Y0_Y1>;
  }
}

multiclass TileST {

  def #NAME#
      : TileSTOREY2
        <0x3,
         (outs),
         (ins CPURegs:$addr, CPURegs:$rs),
         "st\t$addr, $rs",
         [(store (i64 CPURegs:$rs), CPURegs:$addr)],
         IIC_MM, FrmRRR, S_X1_Y2>;

  def #0_X1#
      : TileBundleX1S
        <0x5, 0x31,
         (outs),
         (ins CPURegs:$addr, CPURegs:$rs),
         "st\t$addr, $rs",
         [],
         IIC_MM, FrmRRR, S_X1_Y2>;

  def #0_Y2#
      : TileBundleY2S
        <0x3,
         (outs),
         (ins CPURegs:$addr, CPURegs:$rs),
         "st\t$addr, $rs",
         [],
         IIC_MM, FrmRRR, S_X1_Y2>;

  let isCodeGenOnly = 1 in {
  def #0_Z64_F#
      : TileSTOREY2
        <0x3,
         (outs),
         (ins CPURegs:$addr, CPURegs:$rs),
         "st\t$addr, $rs",
         [(store (f64 CPURegs:$rs), CPURegs:$addr)],
         IIC_MM, FrmRRR, S_X1_Y2>;

  def #0_Z64_V32#
      : TileSTOREY2
        <0x3,
         (outs),
         (ins CPURegs:$addr, SIMDRegs:$rs),
         "st\t$addr, $rs",
         [(store (v2i32 SIMDRegs:$rs), CPURegs:$addr)],
         IIC_MM, FrmRRR, S_X1_Y2>;

  def #0_Z64_V16#
      : TileSTOREY2
        <0x3,
         (outs),
         (ins CPURegs:$addr, SIMDRegs:$rs),
         "st\t$addr, $rs",
         [(store (v4i16 SIMDRegs:$rs), CPURegs:$addr)],
         IIC_MM, FrmRRR, S_X1_Y2>;

  def #0_Z64_V8#
      : TileSTOREY2
        <0x3,
         (outs),
         (ins CPURegs:$addr, SIMDRegs:$rs),
         "st\t$addr, $rs",
         [(store (v8i8 SIMDRegs:$rs), CPURegs:$addr)],
         IIC_MM, FrmRRR, S_X1_Y2>;
  }
}

multiclass TileST1 {

  def #NAME#
      : TileSTOREY2
        <0x0,
         (outs),
         (ins CPURegs:$addr, CPURegs:$rs),
         "st1\t$addr, $rs",
         [(truncstorei8 (i64 CPURegs:$rs), CPURegs:$addr)],
         IIC_MM, FrmRRR, S_X1_Y2>;

  def #0_X1#
      : TileBundleX1S
        <0x5, 0x2A,
         (outs),
         (ins CPURegs:$addr, CPURegs:$rs),
         "st1\t$addr, $rs",
         [],
         IIC_MM, FrmRRR, S_X1_Y2>;

  def #0_Y2#
      : TileBundleY2S
        <0x0,
         (outs),
         (ins CPURegs:$addr, CPURegs:$rs),
         "st1\t$addr, $rs",
         [],
         IIC_MM, FrmRRR, S_X1_Y2>;

  let isCodeGenOnly = 1 in
  def #32#
      : TileSTOREY2
        <0x0,
         (outs),
         (ins CPURegs:$addr, CPU32Regs:$rs),
         "st1\t$addr, $rs",
         [(truncstorei8 (i32 CPU32Regs:$rs), CPURegs:$addr)],
         IIC_MM, FrmRRR, S_X1_Y2>;
}

multiclass TileST2 {

  def #NAME# 
      : TileSTOREY2
        <0x1,
         (outs),
         (ins CPURegs:$addr, CPURegs:$rs),
         "st2\t$addr, $rs",
         [(truncstorei16 (i64 CPURegs:$rs), CPURegs:$addr)],
         IIC_MM, FrmRRR, S_X1_Y2>;

  def #0_X1# 
      : TileBundleX1S
        <0x5, 0x2B,
         (outs),
         (ins CPURegs:$addr, CPURegs:$rs),
         "st2\t$addr, $rs",
         [],
         IIC_MM, FrmRRR, S_X1_Y2>;

  def #0_Y2# 
      : TileBundleY2S
        <0x1,
         (outs),
         (ins CPURegs:$addr, CPURegs:$rs),
         "st2\t$addr, $rs",
         [],
         IIC_MM, FrmRRR, S_X1_Y2>;

  let isCodeGenOnly = 1 in
  def #32#
      : TileSTOREY2
        <0x1,
         (outs),
         (ins CPURegs:$addr, CPU32Regs:$rs),
         "st2\t$addr, $rs",
         [(truncstorei16 (i32 CPU32Regs:$rs), CPURegs:$addr)],
         IIC_MM, FrmRRR, S_X1_Y2>;
}

multiclass TileST4 {
  def #NAME#
      : TileSTOREY2
        <0x2,
         (outs),
         (ins CPU32Regs:$addr, CPU32Regs:$rs),
         "st4\t$addr, $rs",
         [(store (i32 CPU32Regs:$rs), CPU32Regs:$addr)],
         IIC_MM, FrmMM, S_X1_Y2>;

  def #0_X1#
      : TileBundleX1S
        <0x5, 0x2C,
         (outs),
         (ins CPU32Regs:$addr, CPU32Regs:$rs),
         "st4\t$addr, $rs",
         [],
         IIC_MM, FrmMM, S_X1_Y2>;

  def #0_Y2#
      : TileBundleY2S
        <0x2,
         (outs),
         (ins CPU32Regs:$addr, CPU32Regs:$rs),
         "st4\t$addr, $rs",
         [],
         IIC_MM, FrmMM, S_X1_Y2>;

  let isCodeGenOnly = 1 in {
  def #32#
      : TileSTOREY2
        <0x2,
         (outs),
         (ins CPURegs:$addr, CPU32Regs:$rs),
         "st4\t$addr, $rs",
         [(store (i32 CPU32Regs:$rs), CPURegs:$addr)],
         IIC_MM, FrmMM, S_X1_Y2>;

  def #32_F#
      : TileSTOREY2
        <0x2,
         (outs),
         (ins CPURegs:$addr, CPU32Regs:$rs),
         "st4\t$addr, $rs",
         [(store (f32 CPU32Regs:$rs), CPURegs:$addr)],
         IIC_MM, FrmMM, S_X1_Y2>;

  def #64#
      : TileSTOREY2
        <0x2,
         (outs),
         (ins CPURegs:$addr, CPURegs:$rs),
         "st4\t$addr, $rs",
         [(truncstorei32 (i64 CPURegs:$rs), CPURegs:$addr)],
         IIC_MM, FrmRRR, S_X1_Y2>;
  }
}

multiclass TileLD {

  def #NAME#
      : TileLOADY2
        <0x2, 0x3,
         (outs CPURegs:$rd),
         (ins CPURegs:$addr),
         "ld\t$rd, $addr",
         [(set (i64 CPURegs:$rd), (load CPURegs:$addr))],
         IIC_MM, FrmUnary, S_X1_Y2>;

  def #0_X1#
      : TileBundleX1L
        <0x5, 0x35, 0x1D,
         (outs CPURegs:$rd),
         (ins CPURegs:$addr),
         "ld\t$rd, $addr",
         [],
         IIC_MM, FrmUnary, S_X1_Y2>;

  def #0_Y2#
      : TileBundleY2L
        <0x2, 0x3,
         (outs CPURegs:$rd),
         (ins CPURegs:$addr),
         "ld\t$rd, $addr",
         [],
         IIC_MM, FrmUnary, S_X1_Y2>;

  let isCodeGenOnly = 1 in {
  def #0_Z64_F#
      : TileLOADY2
        <0x2, 0x3,
         (outs CPURegs:$rd),
         (ins CPURegs:$addr),
         "ld\t$rd, $addr",
         [(set (f64 CPURegs:$rd), (load CPURegs:$addr))],
         IIC_MM, FrmUnary, S_X1_Y2>;

  def #0_Z64_V32#
      : TileLOADY2
        <0x2, 0x3,
         (outs SIMDRegs:$rd),
         (ins CPURegs:$addr),
         "ld\t$rd, $addr",
         [(set (v2i32 SIMDRegs:$rd), (load CPURegs:$addr))],
         IIC_MM, FrmUnary, S_X1_Y2>;

  def #0_Z64_V16#
      : TileLOADY2
        <0x2, 0x3,
         (outs SIMDRegs:$rd),
         (ins CPURegs:$addr),
         "ld\t$rd, $addr",
         [(set (v4i16 SIMDRegs:$rd), (load CPURegs:$addr))],
         IIC_MM, FrmUnary, S_X1_Y2>;

  def #0_Z64_V8#
      : TileLOADY2
        <0x2, 0x3,
         (outs SIMDRegs:$rd),
         (ins CPURegs:$addr),
         "ld\t$rd, $addr",
         [(set (v8i8 SIMDRegs:$rd), (load CPURegs:$addr))],
         IIC_MM, FrmUnary, S_X1_Y2>;
  }
}

multiclass TileLD1S {

  def #NAME#
      : TileLOADY2
        <0x1, 0x0,
         (outs CPURegs:$rd),
         (ins CPURegs:$addr),
         "ld1s\t$rd, $addr",
         [(set (i64 CPURegs:$rd), (sextloadi8 CPURegs:$addr))],
         IIC_MM, FrmUnary, S_X1_Y2>;

  def #0_X1#
      : TileBundleX1L
        <0x5, 0x35, 0xF,
         (outs CPURegs:$rd),
         (ins CPURegs:$addr),
         "ld1s\t$rd, $addr",
         [],
         IIC_MM, FrmUnary, S_X1_Y2>;

  def #0_Y2#
      : TileBundleY2L
        <0x1, 0x0,
         (outs CPURegs:$rd),
         (ins CPURegs:$addr),
         "ld1s\t$rd, $addr",
         [],
         IIC_MM, FrmUnary, S_X1_Y2>;

  let isCodeGenOnly = 1 in
  def #32#
      : TileLOADY2
        <0x1, 0x0,
         (outs CPU32Regs:$rd),
         (ins CPURegs:$addr),
         "ld1s\t$rd, $addr",
         [(set (i32 CPU32Regs:$rd), (sextloadi8 CPURegs:$addr))],
         IIC_MM, FrmUnary, S_X1_Y2>;
}

multiclass TileLD1U {

  def #NAME#
      : TileLOADY2
        <0x1, 0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$addr),
         "ld1u\t$rd, $addr",
         [(set (i64 CPURegs:$rd), (zextloadi8 CPURegs:$addr))],
         IIC_MM, FrmUnary, S_X1_Y2>;

  def #0_X1#
      : TileBundleX1L
        <0x5, 0x35, 0x10,
         (outs CPURegs:$rd),
         (ins CPURegs:$addr),
         "ld1u\t$rd, $addr",
         [],
         IIC_MM, FrmUnary, S_X1_Y2>;

  def #0_Y2#
      : TileBundleY2L
        <0x1, 0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$addr),
         "ld1u\t$rd, $addr",
         [],
         IIC_MM, FrmUnary, S_X1_Y2>;

  let isCodeGenOnly = 1 in
  def #32#
      : TileLOADY2
        <0x1, 0x1,
         (outs CPU32Regs:$rd),
         (ins CPURegs:$addr),
         "ld1u\t$rd, $addr",
         [(set (i32 CPU32Regs:$rd), (zextloadi8 CPURegs:$addr))],
         IIC_MM, FrmUnary, S_X1_Y2>;
}

multiclass TileLD2S {

  def #NAME#
      : TileLOADY2
        <0x1, 0x2,
         (outs CPURegs:$rd),
         (ins CPURegs:$addr),
         "ld2s\t$rd, $addr",
         [(set (i64 CPURegs:$rd), (sextloadi16 CPURegs:$addr))],
         IIC_MM, FrmUnary, S_X1_Y2>;

  def #0_X1#
      : TileBundleX1L
        <0x5, 0x35, 0x11,
         (outs CPURegs:$rd),
         (ins CPURegs:$addr),
         "ld2s\t$rd, $addr",
         [],
         IIC_MM, FrmUnary, S_X1_Y2>;

  def #0_Y2#
      : TileBundleY2L
        <0x1, 0x2,
         (outs CPURegs:$rd),
         (ins CPURegs:$addr),
         "ld2s\t$rd, $addr",
         [],
         IIC_MM, FrmUnary, S_X1_Y2>;

  let isCodeGenOnly = 1 in
  def #32#
      : TileLOADY2
        <0x1, 0x2,
         (outs CPU32Regs:$rd),
         (ins CPURegs:$addr),
         "ld2s\t$rd, $addr",
         [(set (i32 CPU32Regs:$rd), (sextloadi16 CPURegs:$addr))],
         IIC_MM, FrmUnary, S_X1_Y2>;
}

multiclass TileLD2U {

  def #NAME#
      : TileLOADY2
        <0x1, 0x3,
         (outs CPURegs:$rd),
         (ins CPURegs:$addr),
         "ld2u\t$rd, $addr",
         [(set (i64 CPURegs:$rd), (zextloadi16 CPURegs:$addr))],
         IIC_MM, FrmUnary, S_X1_Y2>;

  def #0_X1#
      : TileBundleX1L
        <0x5, 0x35, 0x12,
         (outs CPURegs:$rd),
         (ins CPURegs:$addr),
         "ld2u\t$rd, $addr",
         [],
         IIC_MM, FrmUnary, S_X1_Y2>;

  def #0_Y2#
      : TileBundleY2L
        <0x1, 0x3,
         (outs CPURegs:$rd),
         (ins CPURegs:$addr),
         "ld2u\t$rd, $addr",
         [],
         IIC_MM, FrmUnary, S_X1_Y2>;

  let isCodeGenOnly = 1 in
  def #32#
      : TileLOADY2
        <0x1, 0x3,
         (outs CPU32Regs:$rd),
         (ins CPURegs:$addr),
         "ld2u\t$rd, $addr",
         [(set (i32 CPU32Regs:$rd), (zextloadi16 CPURegs:$addr))],
         IIC_MM, FrmUnary, S_X1_Y2>;
}

multiclass TileLD4S {

  def #NAME#
      : TileLOADY2
        <0x2, 0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$addr),
         "ld4s\t$rd, $addr",
         [(set (i64 CPURegs:$rd), (sextloadi32 CPURegs:$addr))],
         IIC_MM, FrmUnary, S_X1_Y2>;

  def #0_X1#
      : TileBundleX1L
        <0x5, 0x35, 0x13,
         (outs CPURegs:$rd),
         (ins CPURegs:$addr),
         "ld4s\t$rd, $addr",
         [],
         IIC_MM, FrmUnary, S_X1_Y2>;

  def #0_Y2#
      : TileBundleY2L
        <0x2, 0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$addr),
         "ld4s\t$rd, $addr",
         [],
         IIC_MM, FrmUnary, S_X1_Y2>;

  let isCodeGenOnly = 1 in {
  def #32#
      : TileLOADY2
        <0x2, 0x1,
         (outs CPU32Regs:$rd),
         (ins CPURegs:$addr),
         "ld4s\t$rd, $addr",
         [(set (i32 CPU32Regs:$rd), (load CPURegs:$addr))],
         IIC_MM, FrmUnary, S_X1_Y2>;

  def #32_F#
      : TileLOADY2
        <0x2, 0x1,
         (outs CPU32Regs:$rd),
         (ins CPURegs:$addr),
         "ld4s\t$rd, $addr",
         [(set (f32 CPU32Regs:$rd), (load CPURegs:$addr))],
         IIC_MM, FrmUnary, S_X1_Y2>;
  }
}

multiclass TileLD4U {

  def #NAME#
      : TileLOADY2
        <0x2, 0x2,
         (outs CPURegs:$rd),
         (ins CPURegs:$addr),
         "ld4u\t$rd, $addr",
         [(set (i64 CPURegs:$rd), (zextloadi32 CPURegs:$addr))],
         IIC_MM, FrmUnary, S_X1_Y2>;

  def #0_X1#
      : TileBundleX1L
        <0x5, 0x35, 0x14,
         (outs CPURegs:$rd),
         (ins CPURegs:$addr),
         "ld4u\t$rd, $addr",
         [],
         IIC_MM, FrmUnary, S_X1_Y2>;

  def #0_Y2#
      : TileBundleY2L
        <0x2, 0x2,
         (outs CPURegs:$rd),
         (ins CPURegs:$addr),
         "ld4u\t$rd, $addr",
         [],
         IIC_MM, FrmUnary, S_X1_Y2>;
}

multiclass TileFETCHADD {

  def #NAME#
      : TileInstX1RRR
        <0x5, 0x15,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "fetchadd\t$rd, $rsa, $rsb",
         [(set (i64 CPURegs:$rd),
         (atomic_load_add CPURegs:$rsa, CPURegs:$rsb))],
         IIC_MM, FrmRRR, S_X1>;

  def #0_X1#
      : TileBundleX1RRR
        <0x5, 0x15,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "fetchadd\t$rd, $rsa, $rsb",
         [],
         IIC_MM, FrmRRR, S_X1>;
}

multiclass TileFETCHADD4 {

  def #NAME# 
      : TileInstX1RRR
        <0x5, 0x12,
         (outs CPU32Regs:$rd),
         (ins CPURegs:$rsa, CPU32Regs:$rsb),
         "fetchadd4\t$rd, $rsa, $rsb",
         [(set (i32 CPU32Regs:$rd),
         (atomic_load_add CPURegs:$rsa, CPU32Regs:$rsb))],
         IIC_MM, FrmRRR, S_X1>;

  def #0_X1# 
      : TileBundleX1RRR
        <0x5, 0x12,
         (outs CPU32Regs:$rd),
         (ins CPURegs:$rsa, CPU32Regs:$rsb),
         "fetchadd4\t$rd, $rsa, $rsb",
         [],
         IIC_MM, FrmRRR, S_X1>;
}

multiclass TileFETCHAND {

  def #NAME#
      : TileInstX1RRR
        <0x5, 0x17,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "fetchand\t$rd, $rsa, $rsb",
         [(set (i64 CPURegs:$rd),
         (atomic_load_and CPURegs:$rsa, CPURegs:$rsb))],
         IIC_MM, FrmRRR, S_X1>;

  def #0_X1#
      : TileBundleX1RRR
        <0x5, 0x17,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "fetchand\t$rd, $rsa, $rsb",
         [],
         IIC_MM, FrmRRR, S_X1>;
}

multiclass TileFETCHAND4 {

  def #NAME#
      : TileInstX1RRR
        <0x5, 0x16,
         (outs CPU32Regs:$rd),
         (ins CPURegs:$rsa, CPU32Regs:$rsb),
         "fetchand4\t$rd, $rsa, $rsb",
         [(set (i32 CPU32Regs:$rd),
         (atomic_load_and CPURegs:$rsa, CPU32Regs:$rsb))],
         IIC_MM, FrmRRR, S_X1>;

  def #0_X1#
      : TileBundleX1RRR
        <0x5, 0x16,
         (outs CPU32Regs:$rd),
         (ins CPURegs:$rsa, CPU32Regs:$rsb),
         "fetchand4\t$rd, $rsa, $rsb",
         [],
         IIC_MM, FrmRRR, S_X1>;
}

multiclass TileFETCHOR {

  def #NAME#
      : TileInstX1RRR
        <0x5, 0x19,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "fetchor\t$rd, $rsa, $rsb",
         [(set (i64 CPURegs:$rd),
         (atomic_load_or CPURegs:$rsa, CPURegs:$rsb))],
         IIC_MM, FrmRRR, S_X1>;

  def #0_X1#
      : TileBundleX1RRR
        <0x5, 0x19,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "fetchor\t$rd, $rsa, $rsb",
         [],
         IIC_MM, FrmRRR, S_X1>;
}

multiclass TileFETCHOR4 {

  def #NAME#
      : TileInstX1RRR
        <0x5, 0x18,
         (outs CPU32Regs:$rd),
         (ins CPURegs:$rsa, CPU32Regs:$rsb),
         "fetchor4\t$rd, $rsa, $rsb",
         [(set (i32 CPU32Regs:$rd),
           (atomic_load_or CPURegs:$rsa, CPU32Regs:$rsb))],
         IIC_MM, FrmRRR, S_X1>;

  def #0_X1#
      : TileBundleX1RRR
        <0x5, 0x18,
         (outs CPU32Regs:$rd),
         (ins CPURegs:$rsa, CPU32Regs:$rsb),
         "fetchor4\t$rd, $rsa, $rsb",
         [],
         IIC_MM, FrmRRR, S_X1>;
}

let isCodeGenOnly = 1, isSoloInst = 1 in
multiclass TileATOMIC_CMP_SWAP {
  //FIXME: multi insts
  def #NAME# : TileInst<(outs CPURegs:$rd),
                        (ins CPURegs:$rsa, CPURegs:$rsb, CPURegs:$rsc),
                        "mtspr CMPEXCH_VALUE, $rsb\n\tcmpexch\t$rd, $rsa, $rsc",
                        [(set (i64 CPURegs:$rd),
                          (atomic_cmp_swap
                            CPURegs:$rsa, CPURegs:$rsb, CPURegs:$rsc))],
                        IIC_MM, FrmRRR, S_X1>;

  def #32#   : TileInst<(outs CPU32Regs:$rd),
                        (ins CPURegs:$rsa, CPU32Regs:$rsb, CPU32Regs:$rsc),
                        "mtspr CMPEXCH_VALUE, $rsb\n\tcmpexch4\t$rd, $rsa, $rsc",
                        [(set (i32 CPU32Regs:$rd),
                          (atomic_cmp_swap
                            CPURegs:$rsa, CPU32Regs:$rsb, CPU32Regs:$rsc))],
                        IIC_MM, FrmRRR, S_X1>;
}

multiclass TileEXCH {

  def #NAME#
      : TileInstX1RRR
        <0x5, 0x11,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "exch\t$rd, $rsa, $rsb",
         [(set (i64 CPURegs:$rd),
         (atomic_swap CPURegs:$rsa, CPURegs:$rsb))],
         IIC_MM, FrmRRR, S_X1>;

  def #0_X1#
      : TileBundleX1RRR
        <0x5, 0x11,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "exch\t$rd, $rsa, $rsb",
         [],
         IIC_MM, FrmRRR, S_X1>;
}

multiclass TileEXCH4 {

  def #NAME#
      : TileInstX1RRR
        <0x5, 0x10,
         (outs CPU32Regs:$rd),
         (ins CPURegs:$rsa, CPU32Regs:$rsb),
         "exch4\t$rd, $rsa, $rsb",
         [(set (i32 CPU32Regs:$rd),
         (atomic_swap CPURegs:$rsa, CPU32Regs:$rsb))],
         IIC_MM, FrmRRR, S_X1>;

  def #0_X1#
      : TileBundleX1RRR
        <0x5, 0x10,
         (outs CPU32Regs:$rd),
         (ins CPURegs:$rsa, CPU32Regs:$rsb),
         "exch4\t$rd, $rsa, $rsb",
         [],
         IIC_MM, FrmRRR, S_X1>;
}

multiclass TileV4INT_L {

  def #NAME#
      : TileInstX1RZR
        <0x5, 0x63,
         (outs CPURegs:$rd),
         (ins CPU32Regs:$rs),
         "v4int_l\t$rd, zero, $rs",
         [],
         IIC_SIMD, FrmRRR, S_X0_X1>;

  def #0_X0#
      : TileBundleX0RZR
        <0x5, 0x98,
         (outs CPURegs:$rd),
         (ins CPU32Regs:$rs),
         "v4int_l\t$rd, zero, $rs",
         [],
         IIC_SIMD, FrmRRR, S_X0_X1>;

  def #0_X1#
      : TileBundleX1RZR
        <0x5, 0x63,
         (outs CPURegs:$rd),
         (ins CPU32Regs:$rs),
         "v4int_l\t$rd, zero, $rs",
         [],
         IIC_SIMD, FrmRRR, S_X0_X1>;

  let isCodeGenOnly = 1 in
  def #32#
      : TileInstX1RZR
        <0x5, 0x63,
         (outs CPU32Regs:$rd),
         (ins CPURegs:$rs),
         "v4int_l\t$rd, zero, $rs",
         [],
         IIC_SIMD, FrmRRR, S_X0_X1>;
}

multiclass TileBFEXTU {

  def #NAME#
      : TileInstX0MM
        <0x3, 0x5,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$bfstart, i64imm:$bfend),
         "bfextu\t$rd, $rs, $bfstart, $bfend",
         [(set (i64 CPURegs:$rd),
           (TileBFEXTUNode (i64 CPURegs:$rs), (i64 immSExt64:$bfstart),
                           immSExt64:$bfend))],

         IIC_BIT_P0, FrmRRR, S_X0>;

  def #0_X0#
      : TileBundleX0MM
        <0x3, 0x5,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$bfstart, i64imm:$bfend),
         "bfextu\t$rd, $rs, $bfstart, $bfend",
         [],
         IIC_BIT_P0, FrmRRR, S_X0>;

  let isCodeGenOnly = 1 in {
  def #32#
      : TileInstX0MM
        <0x3, 0x5,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rs, i32imm:$bfstart, i32imm:$bfend),
         "bfextu\t$rd, $rs, $bfstart, $bfend",
         [(set (i32 CPU32Regs:$rd),
           (TileBFEXTUNode (i32 CPU32Regs:$rs), (i32 immSExt32:$bfstart),
                           immSExt32:$bfend))],
         IIC_BIT_P0, FrmRRR, S_X0>;

  def #32_64#
      : TileInstX0MM
        <0x3, 0x5,
         (outs CPU32Regs:$rd),
         (ins CPURegs:$rs, i64imm:$bfstart, i64imm:$bfend),
         "bfextu\t$rd, $rs, $bfstart, $bfend",
         [(set (i32 CPU32Regs:$rd),
           (TileBFEXTUNode (i64 CPURegs:$rs), (i64 immSExt64:$bfstart),
                            immSExt64:$bfend))],
         IIC_BIT_P0, FrmRRR, S_X0>;

  def #64_32#
      : TileInstX0MM
        <0x3, 0x5,
         (outs CPURegs:$rd),
         (ins CPU32Regs:$rs, i32imm:$bfstart, i32imm:$bfend),
         "bfextu\t$rd, $rs, $bfstart, $bfend",
         [(set (i64 CPURegs:$rd),
           (TileBFEXTUNode (i32 CPU32Regs:$rs), (i32 immSExt32:$bfstart),
                            immSExt32:$bfend))],
         IIC_BIT_P0, FrmRRR, S_X0>;
  }
}

let Constraints = "$rd = $rf" in
multiclass TileBFINS {

  def #NAME#
      : TileInstX0MM
        <0x3, 0x6,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$bfstart, i64imm:$bfend, CPURegs:$rf),
         "bfins\t$rd, $rs, $bfstart, $bfend",
         [(set (i64 CPURegs:$rd),
           (TileBFINSNode CPURegs:$rs, (i64 immSExt64:$bfstart),
                          immSExt64:$bfend, CPURegs:$rf))],
         IIC_BIT_P0, FrmRRR, S_X0>;

  def #0_X0#
      : TileBundleX0MM
        <0x3, 0x6,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$bfstart, i64imm:$bfend, CPURegs:$rf),
         "bfins\t$rd, $rs, $bfstart, $bfend",
         [],
         IIC_BIT_P0, FrmRRR, S_X0>;

  let isCodeGenOnly = 1 in
  def #32#
      : TileInstX0MM
        <0x3, 0x6,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rs, i32imm:$bfstart, i32imm:$bfend, CPU32Regs:$rf),
         "bfins\t$rd, $rs, $bfstart, $bfend",
         [(set (i32 CPU32Regs:$rd),
           (TileBFINSNode CPU32Regs:$rs, (i32 immSExt32:$bfstart),
                          immSExt32:$bfend, CPU32Regs:$rf))],
         IIC_BIT_P0, FrmRRR, S_X0>;
}

let isCodeGenOnly = 1 in
multiclass TileLNK {

  def #NAME#
      : TileLNKX1
        <0x5, 0x35, 0x1E,
         (outs PICLNKReg:$rd),
         (ins i64imm:$imm), "$rd",
         [], IIC_CTL_P1, FrmUnary, S_X1>;

  def #0_X1#
      : TileBundleX1LNK
        <0x5, 0x35, 0x1E,
         (outs PICLNKReg:$rd),
         (ins i64imm:$imm), "$rd",
         [], IIC_CTL_P1, FrmUnary, S_X1>;
}

let hasSideEffects = 1 in
multiclass TileMF {

  def #NAME#
      : TileMFX1
        <0x5, 0x35, 0x1F,
         (outs), (ins), "mf",
         [(TileMFNode)], IIC_MMA, FrmUnary, S_X1>;

  def #0_X1#
      : TileBundleX1MF
        <0x5, 0x35, 0x1F,
         (outs), (ins), "mf",
         [], IIC_MMA, FrmUnary, S_X1>;
}

let isBranch = 1, isTerminator = 1, isBarrier = 1 in
multiclass TileJ {

  def #NAME# 
      : TileInstX1Jump
         <0x4, 0x1,
          (outs), (ins jmptarget:$j_target),
          "j\t$j_target",
          [(br bb:$j_target)],
          IIC_CTL, FrmJmp, S_X1>;

  def #0_X1# 
      : TileBundleX1Jump
         <0x4, 0x1,
          (outs), (ins jmptarget:$j_target),
          "j\t$j_target",
          [],
          IIC_CTL, FrmJmp, S_X1>;
}

let isBranch=1, isTerminator=1, isBarrier=1, isIndirectBranch = 1 in
multiclass TileJR {

  def #NAME#
      : TileJRX1
        <0x5, 0x35, 0xE,
         (outs), (ins CPURegs:$rs),
         "jr\t$rs",
         [(brind CPURegs:$rs)],
         IIC_CTL, FrmUnary, S_X1>;

  def #0_X1#
      : TileBundleX1JR
        <0x5, 0x35, 0xE,
         (outs), (ins CPURegs:$rs),
         "jr\t$rs",
         [],
         IIC_CTL, FrmUnary, S_X1>;
}

let isBranch=1, isTerminator=1, isBarrier=1, isIndirectBranch = 1 in
multiclass TileJRP {

  def #NAME#
      : TileJRX1
        <0x5, 0x35, 0xD,
         (outs), (ins CPURegs:$rs),
         "jrp\t$rs",
         [(brind CPURegs:$rs)],
         IIC_CTL, FrmUnary, S_X1>;

  def #0_X1#
      : TileBundleX1JR
        <0x5, 0x35, 0xD,
         (outs), (ins CPURegs:$rs),
         "jrp\t$rs",
         [],
         IIC_CTL, FrmUnary, S_X1>;
}

let isCall=1, Defs=[LR] in
multiclass TileJAL {

  def #NAME#
      : TileInstX1Jump
        <0x4, 0x0,
         (outs), (ins calltarget:$target, variable_ops),
         "jal\t$target",
         [(TileJmpLink imm:$target)],
         IIC_CTL, FrmJmp, S_X1>;

  def #0_X1#
      : TileBundleX1Jump
        <0x4, 0x0,
         (outs), (ins calltarget:$target, variable_ops),
         "jal\t$target",
         [],
         IIC_CTL, FrmJmp, S_X1>;
}

let isCall=1, Defs=[LR] in
multiclass TileJALR {

  def #NAME#
      : TileJRX1
        <0x5, 0x35, 0xC,
         (outs), (ins CPURegs:$rs, variable_ops),
         "jalr\t$rs",
          [(TileJmpLink CPURegs:$rs)],
          IIC_CTL, FrmUnary, S_X1>;

  def #0_X1#
      : TileBundleX1JR
        <0x5, 0x35, 0xC,
         (outs), (ins CPURegs:$rs, variable_ops),
         "jalr\t$rs",
         [],
         IIC_CTL, FrmUnary, S_X1>;
}


let isBranch=1, isTerminator=1, isBarrier=1,
    isIndirectBranch = 1, isCodeGenOnly = 1 in
multiclass TileBRINDJT {

  def #NAME#
      : TileJRX1
        <0x5, 0x35, 0xD,
         (outs), (ins CPURegs:$rs, i64imm:$jt),
         "jrp $rs",
         [(TileBRINDJTNode CPURegs:$rs, tjumptable:$jt)],
         IIC_CTL, FrmUnary, S_X1>;

  def #0_X1#
      : TileBundleX1JR
        <0x5, 0x35, 0xD,
         (outs), (ins CPURegs:$rs, i64imm:$jt),
         "jrp $rs",
         [],
         IIC_CTL, FrmUnary, S_X1>;
}

let isReturn=1, isTerminator=1, isBarrier=1, hasCtrlDep=1 in
multiclass TileRET {

  def #NAME#
      : TileJRX1
        <0x5, 0x35, 0xE,
         (outs), (ins CPURegs:$target),
         "jr\t$target",
         [(TileRetNode CPURegs:$target)],
         IIC_CTL, FrmUnary, S_X1>;

  def #0_X1#
      : TileBundleX1JR
        <0x5, 0x35, 0xE,
         (outs), (ins CPURegs:$target),
         "jr\t$target",
         [],
         IIC_CTL, FrmUnary, S_X1>;
}

let isCommutable = 1 in
multiclass TileMULX {

  def #NAME#
      : TileInstX0RRR
        <0x5, 0x34,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "mulx\t$rd, $rsa, $rsb",
         [(set (i32 CPU32Regs:$rd),
           (mul CPU32Regs:$rsa, CPU32Regs:$rsb))],
         IIC_MUL, FrmRRR, S_X0_Y0>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x34,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "mulx\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0_Y0>;

  def #0_Y0#
      : TileBundleY0RRR
        <0x8, 0x3,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "mulx\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0_Y0>;
}

let isCommutable = 1 in
multiclass TileMUL_HU_LU {

  def #NAME#
      : TileInstX0RRR
        <0x5, 0x3B,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "mul_hu_lu\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x3B,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "mul_hu_lu\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;
}

let isCommutable = 1 in
multiclass TileMUL_LU_LU {

  def #NAME#
      : TileInstX0RRR
        <0x5, 0x3E,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "mul_lu_lu\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0_Y0>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x3E,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "mul_lu_lu\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0_Y0>;

  def #0_Y0#
      : TileBundleY0RRR
        <0xD, 0x3,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "mul_lu_lu\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0_Y0>;

  let isCodeGenOnly = 1 in {
  def #32#
      : TileInstX0RRR
        <0x5, 0x3E,
         (outs CPURegs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "mul_lu_lu\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0_Y0>;
  }
}

let isCommutable = 1 in
multiclass TileMUL_LS_LS {

  def #NAME#
      : TileInstX0RRR
        <0x5, 0x3C,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "mul_ls_ls\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0_Y0>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x3C,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "mul_ls_ls\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0_Y0>;

  def #0_Y0#
      : TileBundleY0RRR
        <0xD, 0x2,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "mul_ls_ls\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0_Y0>;

  let isCodeGenOnly = 1 in {
  def #32#
      : TileInstX0RRR
        <0x5, 0x3C,
         (outs CPURegs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "mul_ls_ls\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0_Y0>;
  }
}

let isCommutable = 1 in
multiclass TileMUL_HU_HU {

  def #NAME#
      : TileInstX0RRR
        <0x5, 0x39,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "mul_hu_hu\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0_Y0>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x39,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "mul_hu_hu\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0_Y0>;

  def #0_Y0#
      : TileBundleY0RRR
        <0xD, 0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "mul_hu_hu\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0_Y0>;
}

let isCommutable = 1 in
multiclass TileMUL_HS_HS {

  def #NAME#
      : TileInstX0RRR
        <0x5, 0x35,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "mul_hs_hs\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0_Y0>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x35,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "mul_hs_hs\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0_Y0>;

  def #0_Y0#
      : TileBundleY0RRR
        <0xD, 0x0,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "mul_hs_hs\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0_Y0>;
}

multiclass TileMUL_HS_HU {

  def #NAME#
      : TileInstX0RRR
        <0x5, 0x36,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "mul_hs_hu\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x36,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "mul_hs_hu\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;
}

multiclass TileMUL_HS_LU {

  def #NAME#
      : TileInstX0RRR
        <0x5, 0x38,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "mul_hs_lu\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x38,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "mul_hs_lu\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;
}

let Constraints = "$rd0 =\t$rd" in
multiclass TileMULA_HU_LU {

  def #NAME#
      : TileInstX0RRR
        <0x5, 0x30,
         (outs CPURegs:$rd),
         (ins CPURegs:$rd0, CPURegs:$rsa, CPURegs:$rsb),
         "mula_hu_lu  \t$rd, $rsa, $rsb",
         [], IIC_MUL, FrmRRR, S_X0>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x30,
         (outs CPURegs:$rd),
         (ins CPURegs:$rd0, CPURegs:$rsa, CPURegs:$rsb),
         "mula_hu_lu  \t$rd, $rsa, $rsb",
         [], IIC_MUL, FrmRRR, S_X0>;
}

let Constraints = "$rd0 =\t$rd" in
multiclass TileMULA_LU_LU {

  def #NAME#
      : TileInstX0RRR
        <0x5, 0x33,
         (outs CPURegs:$rd),
         (ins CPURegs:$rd0, CPURegs:$rsa, CPURegs:$rsb),
         "mula_lu_lu  \t$rd, $rsa, $rsb",
         [], IIC_MUL, FrmRRR, S_X0_Y0>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x33,
         (outs CPURegs:$rd),
         (ins CPURegs:$rd0, CPURegs:$rsa, CPURegs:$rsb),
         "mula_lu_lu  \t$rd, $rsa, $rsb",
         [], IIC_MUL, FrmRRR, S_X0_Y0>;

  def #0_Y0#
      : TileBundleY0RRR
        <0xE, 0x3,
         (outs CPURegs:$rd),
         (ins CPURegs:$rd0, CPURegs:$rsa, CPURegs:$rsb),
         "mula_lu_lu  \t$rd, $rsa, $rsb",
         [], IIC_MUL, FrmRRR, S_X0_Y0>;
}

let isCodeGenOnly = 1 in
multiclass TileVAARG_SP {

  def #NAME#
      : TileInstX1Imm16
        <0x0,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm16),
         "addli\t$rd, $rs, $imm16",
         [(set (i64 CPURegs:$rd),
            (TileVAARG_SPNode CPURegs:$rs, immSExt64:$imm16))],
         IIC_ALU, FrmImm16, S_X0_X1>;

  def #0_X0#
      : TileBundleX0Imm16
        <0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm16),
         "addli\t$rd, $rs, $imm16",
         [],
         IIC_ALU, FrmImm16, S_X0_X1>;

  def #0_X1#
      : TileBundleX1Imm16
        <0x0,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm16),
         "addli\t$rd, $rs, $imm16",
         [],
         IIC_ALU, FrmImm16, S_X0_X1>;
}

let isCodeGenOnly = 1 in
multiclass TileALLOCA_SP {

  def #NAME#
      : TileInstX1RRR
        <0x5, 0x3,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "add\t$rd, $rsa, $rsb",
         [(set (i64 CPURegs:$rd),
            (TileALLOCA_SPNode CPURegs:$rsa, CPURegs:$rsb))],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x3,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "add\t$rd, $rsa, $rsb",
         [],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_X1#
      : TileBundleX1RRR
        <0x5, 0x3,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "add\t$rd, $rsa, $rsb",
         [],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y0#
      : TileBundleY0RRR
        <0x5, 0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "add\t$rd, $rsa, $rsb",
         [],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;

  def #0_Y1#
      : TileBundleY1RRR
        <0x6, 0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "add\t$rd, $rsa, $rsb",
         [],
         IIC_ALU, FrmRRR, S_X0_X1_Y0_Y1>;
}

let isCodeGenOnly = 1 in
multiclass TileALLOCA_ADDR {

  def #NAME#
      : TileInstX1Imm16
        <0x0,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm16),
         "addli\t$rd, $rs, $imm16",
         [(set (i64 CPURegs:$rd),
           (TileALLOCA_ADDRNode CPURegs:$rs, immSExt64:$imm16))],
         IIC_ALU, FrmImm16, S_X0_X1>;

  def #0_X0#
      : TileBundleX0Imm16
        <0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm16),
         "addli\t$rd, $rs, $imm16",
         [],
         IIC_ALU, FrmImm16, S_X0_X1>;

  def #0_X1#
      : TileBundleX1Imm16
        <0x0,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm16),
         "addli\t$rd, $rs, $imm16",
         [],
         IIC_ALU, FrmImm16, S_X0_X1>;
}

let Constraints = "$link =\t$rd", isCodeGenOnly = 1 in
multiclass TileADDI_TLS {

  def #NAME#
      : TileInstX1Imm8
        <0x3, 0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8, CPURegs:$link),
         "addi\t$rd, $rs, $imm8",
         [],
         IIC_ALU, FrmImm8, S_X0_X1_Y0_Y1>;

  def #0_X0#
      : TileBundleX0Imm8
        <0x4, 0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8, CPURegs:$link),
         "addi\t$rd, $rs, $imm8",
         [],
         IIC_ALU, FrmImm8, S_X0_X1_Y0_Y1>;

  def #0_X1#
      : TileBundleX1Imm8
        <0x3, 0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8, CPURegs:$link),
         "addi\t$rd, $rs, $imm8",
         [],
         IIC_ALU, FrmImm8, S_X0_X1_Y0_Y1>;

  def #0_Y0#
      : TileBundleY0Imm8
        <0x0,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8, CPURegs:$link),
         "addi\t$rd, $rs, $imm8",
         [],
         IIC_ALU, FrmImm8, S_X0_X1_Y0_Y1>;

  def #0_Y1#
      : TileBundleY1Imm8
        <0x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8, CPURegs:$link),
         "addi\t$rd, $rs, $imm8",
         [],
         IIC_ALU, FrmImm8, S_X0_X1_Y0_Y1>;
}

let isCodeGenOnly = 1 in
multiclass TileLD_TLS {

  def #NAME#
      : TileInstX1Imm8
        <0x3, 0x14,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "ld_tls\t$rd, $rs, $imm8",
         [],
         IIC_PSEUDO_P1, FrmImm8, S_X1>;

  def #0_X1#
      : TileBundleX1Imm8
        <0x3, 0x14,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         "ld_tls\t$rd, $rs, $imm8",
         [],
         IIC_PSEUDO_P1, FrmImm8, S_X1>;
}

//===----------------------------------------------------------------------===//
// Pseudo instructions
//===----------------------------------------------------------------------===//

// As stack alignment is always done with addiu, we need a 16-bit immediate.
let Defs = [SP], Uses = [SP] in {
def ADJCALLSTACKDOWN : TilePseudo<(outs), (ins i32imm:$amt),
                                  "!ADJCALLSTACKDOWN $amt",
                                  [(callseq_start timm:$amt)], IIC_PSEUDO_ALL>;
def ADJCALLSTACKUP   : TilePseudo<(outs), (ins i32imm:$amt1, i32imm:$amt2),
                                  "!ADJCALLSTACKUP $amt1",
                                  [(callseq_end timm:$amt1, timm:$amt2)], IIC_PSEUDO_ALL>;
}

// Tile do not support off(base) addressing mode,
// we should expand that to
//
//   ALU R, (i64 ZERO), Index
//   LOAD/STORE R, SRC
def frameIndex : Operand<i64>, ComplexPattern<i64, 1, "SelectFI", [frameindex]> {
  let MIOperandInfo = (ops i64imm);
}

def TileFI : TilePseudo<(outs CPURegs:$Dest),
                        (ins frameIndex:$idx),
                        "",
                        [(set CPURegs:$Dest, frameIndex:$idx)], IIC_MM>;

//===----------------------------------------------------------------------===//
// Instruction definition.
//===----------------------------------------------------------------------===//
// ALU/LOGIC
defm ADD    : TileADD;
defm ADDX   : TileADDX;
defm ADDI   : TileADDI;
defm ADDLI  : TileADDLI;
defm ADDXI  : TileADDXI;
defm ADDXLI : TileADDXLI;
defm SUB    : TileSUB;
defm SUBX   : TileSUBX;
defm AND    : TileAND;
defm OR     : TileOR;
defm XOR    : TileXOR;
defm NOR    : TileNOR;
defm SHL    : TileSHL;
defm SHLX   : TileSHLX;
defm SHLI   : TileSHLI;
defm SHLXI  : TileSHLXI;
defm SHRU   : TileSHRU;
defm SHRUX  : TileSHRUX;
defm SHRUI  : TileSHRUI;
defm SHRUXI : TileSHRUXI;
defm SHRS   : TileSHRS;
defm SHRSI  : TileSHRSI;
defm ANDI   : TileANDI;
defm ORI    : TileORI;
defm XORI   : TileXORI;
defm MOVEI  : TileMOVEI;
defm MOVELI : TileMOVELI;
defm SHL16INSLI : TileSHL16INSLI;

// BIT
defm CLZ  : TileCLZ;
defm CTZ  : TileCTZ;
defm ROTL : TileROTL;
defm ROTLI: TileROTLI;
defm PCNT : TilePCNT;
defm REVBYTES: TileREVBYTES;
defm V4INT_L : TileV4INT_L;
defm BFEXTU  : TileBFEXTU;
defm BFINS   : TileBFINS;


// CMP
defm CMPEQ   : TileCMPEQ;
defm CMPEQI  : TileCMPEQI;
defm CMPNE   : TileCMPNE;
defm CMPLES  : TileCMPLES;
defm CMPLEU  : TileCMPLEU;
defm CMPLTS  : TileCMPLTS;
defm CMPLTU  : TileCMPLTU;
defm CMPLTSI : TileCMPLTSI;
defm CMPLTUI : TileCMPLTUI;


// LOAD/STORE
defm LD      : TileLD;
defm LD1S    : TileLD1S;
defm LD1U    : TileLD1U;
defm LD2S    : TileLD2S;
defm LD2U    : TileLD2U;
defm LD4S    : TileLD4S;
defm LD4U    : TileLD4U;
defm ST      : TileST;
defm ST1     : TileST1;
defm ST2     : TileST2;
defm ST4     : TileST4;

// CMOVE
defm CMOVNEZ  : TileCMOVNEZ;

// ATOMIC
defm FETCHADD  : TileFETCHADD;
defm FETCHADD4 : TileFETCHADD4;
defm FETCHAND  : TileFETCHAND;
defm FETCHAND4 : TileFETCHAND4;
defm FETCHOR   : TileFETCHOR;
defm FETCHOR4  : TileFETCHOR4;
defm ATOMIC_CMP_SWAP : TileATOMIC_CMP_SWAP;
defm EXCH     : TileEXCH;
defm EXCH4    : TileEXCH4;

// BRANCH
defm BNEZ   : TileBNEZ;
defm BEQZ   : TileBEQZ;
defm BLEZ   : TileBLEZ;
defm BLTZ   : TileBLTZ;
defm BGEZ   : TileBGEZ;
defm BGTZ   : TileBGTZ;
defm J      : TileJ;
defm JR     : TileJR;
defm JRP    : TileJRP;
defm JAL    : TileJAL;
defm JALR   : TileJALR;
defm RET    : TileRET;
defm BRINDJT: TileBRINDJT;

// MUL
defm MULX   : TileMULX;
defm MUL_HU_LU   : TileMUL_HU_LU;
defm MUL_LU_LU   : TileMUL_LU_LU;
defm MUL_LS_LS   : TileMUL_LS_LS;
defm MUL_HU_HU   : TileMUL_HU_HU;
defm MUL_HS_HS   : TileMUL_HS_HS;
defm MUL_HS_HU   : TileMUL_HS_HU;
defm MUL_HS_LU   : TileMUL_HS_LU;
defm MULA_HU_LU  : TileMULA_HU_LU;
defm MULA_LU_LU  : TileMULA_LU_LU;

// SPECIAL
defm LNK    : TileLNK;
defm MF     : TileMF;
defm ADD_EXTEND : TileADD_EXTEND;
defm ADD_TRUNC  : TileADD_TRUNC;
defm VAARG_SP   : TileVAARG_SP;
defm ALLOCA_SP  : TileALLOCA_SP;
defm ALLOCA_ADDR: TileALLOCA_ADDR;
defm ADDI_TLS   : TileADDI_TLS;
defm LD_TLS     : TileLD_TLS;

// 64-to-32-bit truncation.
def : Pat<(i32 (trunc CPURegs:$src)),
           (ADD_TRUNC (V4INT_L32 CPURegs:$src))>;

// 32-to-64-bit extension.
def : Pat<(i64 (sext CPU32Regs:$src)), (ADD_EXTEND CPU32Regs:$src)>;
def : Pat<(i64 (anyext CPU32Regs:$src)), (ADD_EXTEND CPU32Regs:$src)>;
def : Pat<(i64 (zext CPU32Regs:$src)), (V4INT_L CPU32Regs:$src)>;


//===----------------------------------------------------------------------===//
//  Arbitrary patterns that map to one or more instructions.
//===----------------------------------------------------------------------===//

// Small immediates.
def : Pat<(i64 immSExt8:$in),
          (ADDI (i64 ZERO), imm:$in)>;
def : Pat<(i64 immSExt16:$in),
          (ADDLI (i64 ZERO), imm:$in)>;
def : Pat<(i64 immZExt16:$in),
          (SHL16INSLI (i64 ZERO), imm:$in)>;
def : Pat<(i32 immSExt8:$in),
          (ADDXI (i32 ZERO_32), imm:$in)>;
def : Pat<(i32 immSExt16:$in),
          (ADDXLI (i32 ZERO_32), imm:$in)>;
def : Pat<(i32 immZExt16:$in),
          (SHL16INSLI32 (i32 ZERO_32), imm:$in)>;

def : Pat<(i64 immSExt32:$in),
          (SHL16INSLI (MOVELI (HI16 imm:$in)), (LO16 imm:$in))>;
def : Pat<(i64 immZExt32:$in),
          (SHL16INSLI (SHL16INSLI (i64 ZERO), (HI16 imm:$in)), (LO16 imm:$in))>;
def : Pat<(i32 immSExt32:$in),
          (SHL16INSLI32 (MOVELI32 (HI16 imm:$in)), (LO16 imm:$in))>;

def : Pat<(i64 immSExt48:$in),
          (SHL16INSLI
            (SHL16INSLI
              (MOVELI (HI32 imm:$in)),
              (HI16 imm:$in)),
           (LO16 imm:$in))>;

def : Pat<(i64 immZExt48:$in),
          (SHL16INSLI
            (SHL16INSLI
              (SHL16INSLI (i64 ZERO), (HI32 imm:$in)),
              (HI16 imm:$in)),
           (LO16 imm:$in))>;

def : Pat<(i64 immSExt64:$in),
          (SHL16INSLI
            (SHL16INSLI
              (SHL16INSLI
                (MOVELI (HI48 imm:$in)),
                (HI32 imm:$in)),
              (HI16 imm:$in)),
           (LO16 imm:$in))>;

// Call
def : Pat<(TileJmpLink tglobaltlsaddr:$dst),
          (JAL tglobaltlsaddr:$dst)>;
def : Pat<(TileJmpLink tglobaladdr:$dst),
          (JAL tglobaladdr:$dst)>;
def : Pat<(TileJmpLink texternalsym:$dst),
          (JAL texternalsym:$dst)>;
def : Pat<(TileJmpLink CPURegs:$dst),
          (JALR CPURegs:$dst)>;

def : Pat<(TileTLSRADD0 CPURegs:$in1, tglobaltlsaddr:$in2, CPURegs:$link),
          (ADDI_TLS CPURegs:$in1, tglobaltlsaddr:$in2, CPURegs:$link)>;
def : Pat<(TileTLSRADD1 CPURegs:$in1, tglobaltlsaddr:$in2),
          (ADDI CPURegs:$in1, tglobaltlsaddr:$in2)>;
def : Pat<(TileTLSGD CPURegs:$in1, tglobaltlsaddr:$in2),
           (SHL16INSLI CPURegs:$in1, tglobaltlsaddr:$in2)>;
def : Pat<(TileLDTLS CPURegs:$in1, tglobaltlsaddr:$in2),
           (LD_TLS CPURegs:$in1, tglobaltlsaddr:$in2)>;
def : Pat<(TileMOVE tglobaltlsaddr:$in),(MOVELI tglobaltlsaddr:$in)>;

// Jump table
def : Pat<(TileMOVE tjumptable:$in), (MOVELI tjumptable:$in)>;
def : Pat<(TileSAR16 CPURegs:$in1, tjumptable:$in2),
           (SHL16INSLI CPURegs:$in1, tjumptable:$in2)>;

// Global address
def : Pat<(TileMOVE tglobaladdr:$in),(MOVELI tglobaladdr:$in)>;
def : Pat<(TileSAR16 CPURegs:$in1, tglobaladdr:$in2),
           (SHL16INSLI CPURegs:$in1, tglobaladdr:$in2)>;

// Block address
def : Pat<(TileMOVE tblockaddress:$in),(MOVELI tblockaddress:$in)>;
def : Pat<(TileSAR16 CPURegs:$in1, tblockaddress:$in2),
           (SHL16INSLI CPURegs:$in1, tblockaddress:$in2)>;

// Constpool
def : Pat<(TileMOVE tconstpool:$in),(MOVELI tconstpool:$in)>;
def : Pat<(TileSAR16 CPURegs:$in1, tconstpool:$in2),
           (SHL16INSLI CPURegs:$in1, tconstpool:$in2)>;

// Tile does not have "not", so we expand to NOR.
def : Pat<(not CPURegs:$in),
          (NOR CPURegs:$in, (i64 ZERO))>;
def : Pat<(not CPU32Regs:$in),
          (NOR32 CPU32Regs:$in, (i32 ZERO_32))>;

def : Pat<(store (i32 0), CPURegs:$dst), (ST432 CPURegs:$dst, (i32 ZERO_32))>;
def : Pat<(store (i64 0), CPURegs:$dst), (ST CPURegs:$dst, (i64 ZERO))>;

def : Pat<(brcond CPURegs:$cond, bb:$dst),
          (BNEZ CPURegs:$cond, bb:$dst)>;
def : Pat<(brcond CPU32Regs:$cond, bb:$dst),
          (BNEZ32 CPU32Regs:$cond, bb:$dst)>;

def : Pat<(i64 (setgt (i64 CPURegs:$lhs), CPURegs:$rhs)),
          (CMPLTS CPURegs:$rhs, CPURegs:$lhs)>;
def : Pat<(i32 (setgt (i64 CPURegs:$lhs), CPURegs:$rhs)),
          (CMPLTS32_64 CPURegs:$rhs, CPURegs:$lhs)>;

def : Pat<(i64 (setugt (i64 CPURegs:$lhs), CPURegs:$rhs)),
          (CMPLTU CPURegs:$rhs, CPURegs:$lhs)>;
def : Pat<(i32 (setugt (i64 CPURegs:$lhs), CPURegs:$rhs)),
          (CMPLTU32_64 CPURegs:$rhs, CPURegs:$lhs)>;

def : Pat<(i64 (setge (i64 CPURegs:$lhs), CPURegs:$rhs)),
          (XORI (CMPLTS CPURegs:$lhs, CPURegs:$rhs), 1)>;
def : Pat<(i32 (setge (i64 CPURegs:$lhs), CPURegs:$rhs)),
          (XORI32 (CMPLTS32_64 CPURegs:$lhs, CPURegs:$rhs), 1)>;

def : Pat<(i64 (setuge (i64 CPURegs:$lhs), CPURegs:$rhs)),
          (XORI (CMPLTU CPURegs:$lhs, CPURegs:$rhs), 1)>;
def : Pat<(i32 (setuge (i64 CPURegs:$lhs), CPURegs:$rhs)),
          (XORI32 (CMPLTU32_64 CPURegs:$lhs, CPURegs:$rhs), 1)>;

def : Pat<(brcond (i32 (setle (i64 CPURegs:$lhs), CPURegs:$rhs)), bb:$dst),
            (BNEZ (CMPLES CPURegs:$lhs, CPURegs:$rhs), bb:$dst)>;
def : Pat<(brcond (i32 (setule (i64 CPURegs:$lhs), CPURegs:$rhs)), bb:$dst),
            (BNEZ (CMPLEU CPURegs:$lhs, CPURegs:$rhs), bb:$dst)>;
def : Pat<(brcond (i32 (setge (i64 CPURegs:$lhs), CPURegs:$rhs)), bb:$dst),
            (BEQZ (CMPLTS CPURegs:$lhs, CPURegs:$rhs), bb:$dst)>;
def : Pat<(brcond (i32 (setge (i64 CPURegs:$lhs), immSExt8:$rhs)), bb:$dst),
            (BEQZ (CMPLTSI CPURegs:$lhs, immSExt8:$rhs), bb:$dst)>;
def : Pat<(brcond (i32 (setuge (i64 CPURegs:$lhs), CPURegs:$rhs)), bb:$dst),
            (BEQZ (CMPLTU CPURegs:$lhs, CPURegs:$rhs), bb:$dst)>;
def : Pat<(brcond (i32 (setuge (i64 CPURegs:$lhs), immSExt8:$rhs)), bb:$dst),
            (BEQZ (CMPLTUI CPURegs:$lhs, immSExt8:$rhs), bb:$dst)>;

// Extended loads.
def : Pat<(i64 (extloadi8  CPURegs:$src)), (LD1U CPURegs:$src)>;
def : Pat<(i32 (extloadi8  CPURegs:$src)), (LD1U32 CPURegs:$src)>;
def : Pat<(i64 (extloadi16 CPURegs:$src)), (LD2U CPURegs:$src)>;
def : Pat<(i32 (extloadi16 CPURegs:$src)), (LD2U32 CPURegs:$src)>;
def : Pat<(i64 (extloadi32 CPURegs:$src)), (LD4U CPURegs:$src)>;

// For adde/sube, we will extend them into a sequence
// of instructions in ISelDAGToDAG pass.
def : Pat<(subc CPU32Regs:$lhs, CPU32Regs:$rhs),
           (SUBX CPU32Regs:$lhs, CPU32Regs:$rhs)>;
def : Pat<(addc CPU32Regs:$lhs, CPU32Regs:$rhs),
           (ADDX CPU32Regs:$lhs, CPU32Regs:$rhs)>;
def : Pat<(addc CPU32Regs:$src, immSExt16:$imm),
           (ADDXLI CPU32Regs:$src, imm:$imm)>;
def : Pat<(subc CPURegs:$lhs, CPURegs:$rhs),
           (SUB CPURegs:$lhs, CPURegs:$rhs)>;
def : Pat<(addc CPURegs:$lhs, CPURegs:$rhs),
           (ADD CPURegs:$lhs, CPURegs:$rhs)>;
def : Pat<(addc CPURegs:$src, immSExt16:$imm),
           (ADDLI CPURegs:$src, imm:$imm)>;

def : Pat<(atomic_fence (imm), (imm)), (MF)>;

//===----------------------------------------------------------------------===//
// Intrinsic support for special purpose control instructions
//===----------------------------------------------------------------------===//
multiclass TileMFSPR_INTRINSIC
             <string OpStr,
              bits<3>op_x1, bits<8>subop_x1,
              SDPatternOperator intrinsic_op> {

  def #NAME#
      : TileInstX1MFIMM14
        <op_x1, subop_x1,
         (outs CPURegs:$rd),
         (ins i64imm:$imm14),
         !strconcat(OpStr, "\t$rd, $imm14"),
         [(set (i64 CPURegs:$rd),
            (intrinsic_op immZExt14:$imm14))],
         IIC_CTL_P1, FrmMFImm14, S_X1>;

  def #0_X1#
      : TileBundleX1MFIMM14
        <op_x1, subop_x1,
         (outs CPURegs:$rd),
         (ins i64imm:$imm14),
         !strconcat(OpStr, "\t$rd, $imm14"),
         [],
         IIC_CTL_P1, FrmMFImm14, S_X1>;
}

multiclass TileMTSPR_INTRINSIC
             <string OpStr,
              bits<3>op_x1, bits<8>subop_x1,
              SDPatternOperator intrinsic_op> {

  def #NAME#
      : TileInstX1MTIMM14
        <op_x1, subop_x1,
         (outs),
         (ins i64imm:$imm14, CPURegs:$rs),
         !strconcat(OpStr, "\t$imm14, $rs"),
         [(intrinsic_op immZExt14:$imm14, CPURegs:$rs)],
         IIC_CTL_P1, FrmMFImm14, S_X1>;

  def #0_X1#
      : TileBundleX1MTIMM14
        <op_x1, subop_x1,
         (outs),
         (ins i64imm:$imm14, CPURegs:$rs),
         !strconcat(OpStr, "\t$imm14, $rs"),
         [],
         IIC_CTL_P1, FrmMFImm14, S_X1>;
}

defm MFSPR_INTRINSIC
     : TileMFSPR_INTRINSIC
       <"mfspr", 0x3, 0x16, int_tilegx_mfspr>;
defm MTSPR_INTRINSIC
     : TileMTSPR_INTRINSIC
       <"mtspr", 0x3, 0x17, int_tilegx_mtspr>;


//===----------------------------------------------------------------------===//
// Floating Point Support
//===----------------------------------------------------------------------===//
include "TileInstrFP.td"

//===----------------------------------------------------------------------===//
// SIMD Support
//===----------------------------------------------------------------------===//
include "TileInstrSIMD.td"
