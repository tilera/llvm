//===- TileInstrFP.td - TILE-Gx Float Instr Information -*- tablegen -*-=//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===-----------------------------------------------------------------===//
//
// This file describes TILE-Gx float point instructions.
//
//   for details, please see
//     http://www.tilera.com/scm/docs/UG401-ISA.pdf, chapter 7
//===-----------------------------------------------------------------===//

multiclass TileFSINGLE_MUL1 {

  def #NAME#
      : TileInstX0RRR
        <0x5, 0x24,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "fsingle_mul1 $rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x24,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "fsingle_mul1 $rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;
}

multiclass TileFSINGLE_MUL2 {

  def #NAME#
      : TileInstX0RRR
        <0x5, 0x25,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "fsingle_mul2 $rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x25,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "fsingle_mul2 $rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;
}

multiclass TileFSINGLE_PACK1 {

  def #NAME#
      : TileInstX0Unary
        <0x5, 0x52, 0x4,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rs),
         "fsingle_pack1 $rd, $rs",
         [],
         IIC_MUL, FrmRRR, S_X0_Y0>;

  def #0_X0#
      : TileBundleX0Unary
        <0x5, 0x52, 0x4,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rs),
         "fsingle_pack1 $rd, $rs",
         [],
         IIC_MUL, FrmRRR, S_X0_Y0>;

  def #0_Y0#
      : TileBundleY0Unary
        <0x6, 0x3, 0x4,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rs),
         "fsingle_pack1 $rd, $rs",
         [],
         IIC_MUL, FrmRRR, S_X0_Y0>;
}

multiclass TileFSINGLE_PACK2 {

  def #NAME#
      : TileInstX0RRR
        <0x5, 0x26,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "fsingle_pack2 $rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x26,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "fsingle_pack2 $rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;
}

def FSINGLE_MUL
    : TilePseudo
      <(outs CPU32Regs:$rd),
       (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
       "#fsingle_mul",
       [(set (f32 CPU32Regs:$rd),
          (fmul CPU32Regs:$rsa, CPU32Regs:$rsb))],
       IIC_MUL>;

defm FSINGLE_MUL1  : TileFSINGLE_MUL1;
defm FSINGLE_MUL2  : TileFSINGLE_MUL2;
defm FSINGLE_PACK1 : TileFSINGLE_PACK1;
defm FSINGLE_PACK2 : TileFSINGLE_PACK2;
