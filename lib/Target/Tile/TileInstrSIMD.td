//===- TileInstrSIMD.td - TILE-Gx SIMD Instr Information -*- tablegen -*-=//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===------------------------------------------------------------------===//
//
// This file describes TILE-Gx SIMD instructions.
//
//   for details, please see
//     http://www.tilera.com/scm/docs/UG401-ISA.pdf, chapter 14
//===------------------------------------------------------------------===//

multiclass TileVADD<ValueType Ty, string OpStr, bits<3>op_x0,
                    bits<10>op_x0_sub, bits<3>op_x1, bits<10> op_x1_sub,
                    SDPatternOperator intrinsic_op> {

  def #NAME#
      : TileInstX1RRR
        <op_x1, op_x1_sub,
         (outs SIMDRegs:$rd),
         (ins SIMDRegs:$rsa, SIMDRegs:$rsb),
         !strconcat(OpStr, "\t$rd, $rsa, $rsb"),
         [(set (Ty SIMDRegs:$rd),
            (add SIMDRegs:$rsa, SIMDRegs:$rsb))],
         IIC_SIMD, FrmRRR, S_X0_X1>;

  def #0_X0#
      : TileBundleX0RRR
        <op_x0, op_x0_sub,
         (outs SIMDRegs:$rd),
         (ins SIMDRegs:$rsa, SIMDRegs:$rsb),
         !strconcat(OpStr, "\t$rd, $rsa, $rsb"),
         [],
         IIC_SIMD, FrmRRR, S_X0_X1>;

  def #0_X1#
      : TileBundleX1RRR
        <op_x1, op_x1_sub,
         (outs SIMDRegs:$rd),
         (ins SIMDRegs:$rsa, SIMDRegs:$rsb),
         !strconcat(OpStr, "\t$rd, $rsa, $rsb"),
         [],
         IIC_SIMD, FrmRRR, S_X0_X1>;


  let isCodeGenOnly = 1 in
  def #0_ZIntrinsic#
      : TileInstX1RRR
        <op_x1, op_x1_sub,
         (outs SIMDRegs:$rd),
         (ins SIMDRegs:$rsa, SIMDRegs:$rsb),
         !strconcat(OpStr, "\t$rd, $rsa, $rsb"),
         [(set (Ty SIMDRegs:$rd),
           (intrinsic_op SIMDRegs:$rsa, SIMDRegs:$rsb))],
         IIC_SIMD, FrmRRR, S_X0_X1>;
}

multiclass TileVSUB<ValueType Ty, string OpStr, bits<3>op_x0,
                    bits<10>op_x0_sub, bits<3>op_x1, bits<10> op_x1_sub,
                    SDPatternOperator intrinsic_op> {

  def #NAME#
      : TileInstX1RRR
        <op_x1, op_x1_sub,
         (outs SIMDRegs:$rd),
         (ins SIMDRegs:$rsa, SIMDRegs:$rsb),
         !strconcat(OpStr, "\t$rd, $rsa, $rsb"),
         [(set (Ty SIMDRegs:$rd),
            (sub SIMDRegs:$rsa, SIMDRegs:$rsb))],
         IIC_SIMD, FrmRRR, S_X0_X1>;

  def #0_X0#
      : TileBundleX0RRR
        <op_x0, op_x0_sub,
         (outs SIMDRegs:$rd),
         (ins SIMDRegs:$rsa, SIMDRegs:$rsb),
         !strconcat(OpStr, "\t$rd, $rsa, $rsb"),
         [],
         IIC_SIMD, FrmRRR, S_X0_X1>;

  def #0_X1#
      : TileBundleX1RRR
        <op_x1, op_x1_sub,
         (outs SIMDRegs:$rd),
         (ins SIMDRegs:$rsa, SIMDRegs:$rsb),
         !strconcat(OpStr, "\t$rd, $rsa, $rsb"),
         [],
         IIC_SIMD, FrmRRR, S_X0_X1>;

  let isCodeGenOnly = 1 in
  def #0_ZIntrinsic#
      : TileInstX1RRR
        <op_x1, op_x1_sub,
         (outs SIMDRegs:$rd),
         (ins SIMDRegs:$rsa, SIMDRegs:$rsb),
         !strconcat(OpStr, "\t$rd, $rsa, $rsb"),
         [(set (Ty SIMDRegs:$rd),
            (intrinsic_op SIMDRegs:$rsa, SIMDRegs:$rsb))],
         IIC_SIMD, FrmRRR, S_X0_X1>;
}

defm V1ADD    : TileVADD<v8i8, "v1add", 0x5, 0x54, 0x5, 0x37, int_tilegx_v1add>;
defm V2ADD    : TileVADD<v4i16, "v2add", 0x5, 0x74, 0x5, 0x4A, int_tilegx_v2add>;
defm V4ADD    : TileVADD<v2i32, "v4add", 0x5, 0x96, 0x5, 0x61, int_tilegx_v4add>;
defm V1SUB    : TileVSUB<v8i8, "v1sub", 0x5, 0x72, 0x5, 0x48, int_tilegx_v1sub>;
defm V2SUB    : TileVSUB<v4i16, "v2sub", 0x5, 0x94, 0x5, 0x5F, int_tilegx_v2sub>;
defm V4SUB    : TileVSUB<v2i32, "v4sub", 0x5, 0x9F, 0x5, 0x6A, int_tilegx_v4sub>;

def : Pat<(v8i8 (bitconvert (i64 CPURegs:$src))),
           (COPY_TO_REGCLASS CPURegs:$src, SIMDRegs)>;

def : Pat<(v4i16 (bitconvert (i64 CPURegs:$src))),
           (COPY_TO_REGCLASS CPURegs:$src, SIMDRegs)>;

def : Pat<(v2i32 (bitconvert (i64 CPURegs:$src))),
           (COPY_TO_REGCLASS CPURegs:$src, SIMDRegs)>;
