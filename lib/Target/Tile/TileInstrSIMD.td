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
//
// We support SIMD in two ways:
//  1. hand-written intrinsics
//  2. autovectorize
//===------------------------------------------------------------------===//

//===------------------- Intrinsic Support ----------------------===//

multiclass TileVBINRRR_INTRINSIC
             <string OpStr,
              bits<3>op_x0, bits<10>subop_x0,
              bits<3>op_x1, bits<10>subop_x1,
              SDPatternOperator intrinsic_op> {

  def #NAME#
      : TileInstX1RRR
        <op_x1, subop_x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         !strconcat(OpStr, "\t$rd, $rsa, $rsb"),
         [(set (i64 CPURegs:$rd),
            (intrinsic_op CPURegs:$rsa, CPURegs:$rsb))],
         IIC_SIMD, FrmRRR, S_X0_X1>;

  def #0_X0#
      : TileBundleX0RRR
        <op_x0, subop_x0,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         !strconcat(OpStr, "\t$rd, $rsa, $rsb"),
         [],
         IIC_SIMD, FrmRRR, S_X0_X1>;

  def #0_X1#
      : TileBundleX1RRR
        <op_x1, subop_x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         !strconcat(OpStr, "\t$rd, $rsa, $rsb"),
         [],
         IIC_SIMD, FrmRRR, S_X0_X1>;
}

multiclass TileVBINRRR_X0_INTRINSIC
             <string OpStr,
              bits<3>op_x0, bits<10>subop_x0,
              SDPatternOperator intrinsic_op> {

  def #NAME#
      : TileInstX0RRR
        <op_x0, subop_x0,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         !strconcat(OpStr, "\t$rd, $rsa, $rsb"),
         [(set (i64 CPURegs:$rd),
            (intrinsic_op CPURegs:$rsa, CPURegs:$rsb))],
         IIC_SIMD_P0, FrmRRR, S_X0>;

  def #0_X0#
      : TileBundleX0RRR
        <op_x0, subop_x0,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         !strconcat(OpStr, "\t$rd, $rsa, $rsb"),
         [],
         IIC_SIMD_P0, FrmRRR, S_X0>;
}

multiclass TileVBINIMM8_INTRINSIC
             <string OpStr,
              bits<3>op_x0, bits<8>subop_x0,
              bits<3>op_x1, bits<8>subop_x1,
              SDPatternOperator intrinsic_op> {

  def #NAME#
      : TileInstX1Imm8
        <op_x1, subop_x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         !strconcat(OpStr, "\t$rd, $rs, $imm8"),
         [(set (i64 CPURegs:$rd),
            (intrinsic_op CPURegs:$rs, immSExt8:$imm8))],
         IIC_SIMD, FrmImm8, S_X0_X1>;

  def #0_X0#
      : TileBundleX0Imm8
        <op_x0, subop_x0,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         !strconcat(OpStr, "\t$rd, $rs, $imm8"),
         [],
         IIC_SIMD, FrmImm8, S_X0_X1>;

  def #0_X1#
      : TileBundleX1Imm8
        <op_x1, subop_x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$imm8),
         !strconcat(OpStr, "\t$rd, $rs, $imm8"),
         [],
         IIC_SIMD, FrmImm8, S_X0_X1>;
}

multiclass TileVBINSHIFT_INTRINSIC
             <string OpStr,
              bits<3>op_x0, bits<10>subop_x0,
              bits<3>op_x1, bits<10>subop_x1,
              SDPatternOperator intrinsic_op> {

  def #NAME#
      : TileInstX1Shift
        <op_x1, subop_x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$sht),
         !strconcat(OpStr, "\t$rd, $rs, $sht"),
         [(set (i64 CPURegs:$rd),
            (intrinsic_op CPURegs:$rs, immZExt6:$sht))],
         IIC_SIMD, FrmImm8, S_X0_X1>;

  def #0_X0#
      : TileBundleX0Shift
        <op_x0, subop_x0,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$sht),
         !strconcat(OpStr, "\t$rd, $rs, $sht"),
         [],
         IIC_SIMD, FrmImm8, S_X0_X1>;

  def #0_X1#
      : TileBundleX1Shift
        <op_x1, subop_x1,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs, i64imm:$sht),
         !strconcat(OpStr, "\t$rd, $rs, $sht"),
         [],
         IIC_SIMD, FrmImm8, S_X0_X1>;
}

// 8 x 8bit SIMD
defm V1ADD_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v1add", 0x5, 0x54, 0x5, 0x37, int_tilegx_v1add>;
defm V1ADDI_INTRINSIC
     : TileVBINIMM8_INTRINSIC
       <"v1addi", 0x4, 0x8, 0x3, 0x21, int_tilegx_v1addi>;
defm V1ADDUC_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v1adduc", 0x5, 0x53, 0x5, 0x36, int_tilegx_v1adduc>;
defm V1ADIFFU_INTRINSIC
     : TileVBINRRR_X0_INTRINSIC
       <"v1adiffu", 0x5, 0x55, int_tilegx_v1adiffu>;
defm V1AVGU_INTRINSIC
     : TileVBINRRR_X0_INTRINSIC
       <"v1avgu", 0x5, 0x56, int_tilegx_v1avgu>;
defm V1CMPEQ_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v1cmpeq", 0x5, 0x57, 0x5, 0x38, int_tilegx_v1cmpeq>;
defm V1CMPEQI_INTRINSIC
     : TileVBINIMM8_INTRINSIC
       <"v1cmpeqi", 0x4, 0x9, 0x3, 0x22, int_tilegx_v1cmpeqi>;
defm V1CMPLES_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v1cmples", 0x5, 0x58, 0x5, 0x39, int_tilegx_v1cmples>;
defm V1CMPLEU_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v1cmpleu", 0x5, 0x59, 0x5, 0x3A, int_tilegx_v1cmpleu>;
defm V1CMPLTS_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v1cmplts", 0x5, 0x5A, 0x5, 0x3B, int_tilegx_v1cmplts>;
defm V1CMPLTSI_INTRINSIC
     : TileVBINIMM8_INTRINSIC
       <"v1cmpltsi", 0x4, 0xA, 0x3, 0x23, int_tilegx_v1cmpltsi>;
defm V1CMPLTU_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v1cmpltu", 0x5, 0x5B, 0x5, 0x3C, int_tilegx_v1cmpltu>;
defm V1CMPLTUI_INTRINSIC
     : TileVBINIMM8_INTRINSIC
       <"v1cmpltui", 0x4, 0xB, 0x3, 0x24, int_tilegx_v1cmpltu>;
defm V1CMPNE_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v1cmpne", 0x5, 0x5C, 0x5, 0x3D, int_tilegx_v1cmpne>;
defm V1DDOTPU_INTRINSIC
     : TileVBINRRR_X0_INTRINSIC
       <"v1ddotpu", 0x5, 0xA2, int_tilegx_v1ddotpu>;
defm V1DDOTPUA_INTRINSIC
     : TileVBINRRR_X0_INTRINSIC
       <"v1ddotpua", 0x5, 0xA1, int_tilegx_v1ddotpua>;
defm V1DDOTPUS_INTRINSIC
     : TileVBINRRR_X0_INTRINSIC
       <"v1ddotpus", 0x5, 0x5E, int_tilegx_v1ddotpus>;
defm V1DDOTPUSA_INTRINSIC
     : TileVBINRRR_X0_INTRINSIC
       <"v1ddotpusa", 0x5, 0x5D, int_tilegx_v1ddotpusa>;
defm V1DOTP_INTRINSIC
     : TileVBINRRR_X0_INTRINSIC
       <"v1dotp", 0x5, 0x62, int_tilegx_v1dotp>;
defm V1DOTPA_INTRINSIC
     : TileVBINRRR_X0_INTRINSIC
       <"v1dotpa", 0x5, 0x5F, int_tilegx_v1dotpa>;
defm V1DOTPU_INTRINSIC
     : TileVBINRRR_X0_INTRINSIC
       <"v1dotpu", 0x5, 0xA4, int_tilegx_v1dotpu>;
defm V1DOTPUA_INTRINSIC
     : TileVBINRRR_X0_INTRINSIC
       <"v1dotpua", 0x5, 0xA3, int_tilegx_v1dotpua>;
defm V1DOTPUS_INTRINSIC
     : TileVBINRRR_X0_INTRINSIC
       <"v1dotpus", 0x5, 0x61, int_tilegx_v1dotpus>;
defm V1DOTPUSA_INTRINSIC
     : TileVBINRRR_X0_INTRINSIC
       <"v1dotpusa", 0x5, 0x60, int_tilegx_v1dotpusa>;
defm V1INT_H_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v1int_h", 0x5, 0x63, 0x5, 0x3E, int_tilegx_v1int_h>;
defm V1INT_L_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v1int_l", 0x5, 0x64, 0x5, 0x3F, int_tilegx_v1int_l>;
defm V1MAXU_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v1maxu", 0x5, 0x65, 0x5, 0x40, int_tilegx_v1maxu>;
defm V1MAXUI_INTRINSIC
     : TileVBINIMM8_INTRINSIC
       <"v1maxui", 0x4, 0xC, 0x3, 0x25, int_tilegx_v1maxui>;
defm V1MINU_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v1minu", 0x5, 0x66, 0x5, 0x41, int_tilegx_v1minu>;
defm V1MINUI_INTRINSIC
     : TileVBINIMM8_INTRINSIC
       <"v1minui", 0x4, 0xD, 0x3, 0x26, int_tilegx_v1minui>;
defm V1MNZ_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v1mnz", 0x5, 0x67, 0x5, 0x42, int_tilegx_v1mnz>;
defm V1MULTU_INTRINSIC
     : TileVBINRRR_X0_INTRINSIC
       <"v1multu", 0x5, 0x68, int_tilegx_v1multu>;
defm V1MULU_INTRINSIC
     : TileVBINRRR_X0_INTRINSIC
       <"v1mulu", 0x5, 0x6A, int_tilegx_v1mulu>;
defm V1MULUS_INTRINSIC
     : TileVBINRRR_X0_INTRINSIC
       <"v1mulus", 0x5, 0x69, int_tilegx_v1mulus>;
defm V1MZ_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v1mz", 0x5, 0x6B, 0x5, 0x43, int_tilegx_v1mz>;
defm V1SADAU_INTRINSIC
     : TileVBINRRR_X0_INTRINSIC
       <"v1sadau", 0x5, 0x6C, int_tilegx_v1sadau>;
defm V1SADU_INTRINSIC
     : TileVBINRRR_X0_INTRINSIC
       <"v1sadu", 0x5, 0x6D, int_tilegx_v1sadu>;
defm V1SHL_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v1shl", 0x5, 0x6E, 0x5, 0x44, int_tilegx_v1shl>;
defm V1SHLI_INTRINSIC
     : TileVBINSHIFT_INTRINSIC
       <"v1shli", 0x6, 0x7, 0x6, 0x7, int_tilegx_v1shli>;
defm V1SHRS_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v1shrs", 0x5, 0x6F, 0x5, 0x45, int_tilegx_v1shrs>;
defm V1SHRSI_INTRINSIC
     : TileVBINSHIFT_INTRINSIC
       <"v1shrsi", 0x6, 0x8, 0x6, 0x8, int_tilegx_v1shrsi>;
defm V1SHRU_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v1shru", 0x5, 0x70, 0x5, 0x46, int_tilegx_v1shru>;
defm V1SHRUI_INTRINSIC
     : TileVBINSHIFT_INTRINSIC
       <"v1shrui", 0x6, 0x9, 0x6, 0x9, int_tilegx_v1shrui>;
defm V1SUB_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v1sub", 0x5, 0x72, 0x5, 0x48, int_tilegx_v1sub>;
defm V1SUBUC_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v1subuc", 0x5, 0x71, 0x5, 0x47, int_tilegx_v1subuc>;

// 4 x 16bit SIMD
defm V2ADD_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v2add", 0x5, 0x74, 0x5, 0x4A, int_tilegx_v2add>;
defm V2ADDI_INTRINSIC
     : TileVBINIMM8_INTRINSIC
       <"v2addi", 0x4, 0xE, 0x3, 0x27, int_tilegx_v2addi>;
defm V2ADDSC_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v2addi", 0x5, 0x73, 0x4, 0x49, int_tilegx_v2addsc>;
defm V2ADIFFS_INTRINSIC
     : TileVBINRRR_X0_INTRINSIC
       <"v2adiffs", 0x5, 0x75, int_tilegx_v2adiffs>;
defm V2AVGS_INTRINSIC
     : TileVBINRRR_X0_INTRINSIC
       <"v2avgs", 0x5, 0x76, int_tilegx_v2avgs>;
defm V2CMPEQ_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v2cmpeq", 0x5, 0x77, 0x5, 0x4B, int_tilegx_v2cmpeq>;
defm V2CMPEQI_INTRINSIC
     : TileVBINIMM8_INTRINSIC
       <"v2cmpeqi", 0x4, 0xF, 0x3, 0x28, int_tilegx_v2cmpeqi>;
defm V2CMPLES_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v2cmples", 0x5, 0x78, 0x5, 0x4C, int_tilegx_v2cmples>;
defm V2CMPLEU_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v2cmpleu", 0x5, 0x79, 0x5, 0x4D, int_tilegx_v2cmpleu>;
defm V2CMPLTS_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v2cmplts", 0x5, 0x7A, 0x5, 0x4E, int_tilegx_v2cmplts>;
defm V2CMPLTSI_INTRINSIC
     : TileVBINIMM8_INTRINSIC
       <"v2cmpltsi", 0x4, 0x10, 0x3, 0x29, int_tilegx_v2cmpltsi>;
defm V2CMPLTU_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v2cmpltu", 0x5, 0x7B, 0x5, 0x4F, int_tilegx_v2cmpltu>;
defm V2CMPLTUI_INTRINSIC
     : TileVBINIMM8_INTRINSIC
       <"v2cmpltui", 0x4, 0x11, 0x3, 0x2A, int_tilegx_v2cmpltui>;
defm V2CMPNE_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v2cmpne", 0x5, 0x7C, 0x5, 0x50, int_tilegx_v2cmpne>;
defm V2DOTP_INTRINSIC
     : TileVBINRRR_X0_INTRINSIC
       <"v2dotp", 0x5, 0x7E, int_tilegx_v2dotp>;
defm V2DOTPA_INTRINSIC
     : TileVBINRRR_X0_INTRINSIC
       <"v2dotpa", 0x5, 0x7D, int_tilegx_v2dotpa>;
defm V2INT_H_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v2int_h", 0x5, 0x7F, 0x5, 0x51, int_tilegx_v2int_h>;
defm V2INT_L_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v2int_l", 0x5, 0x80, 0x5, 0x52, int_tilegx_v2int_l>;
defm V2MAXS_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v2maxs", 0x5, 0x81, 0x5, 0x53, int_tilegx_v2maxs>;
defm V2MAXSI_INTRINSIC
     : TileVBINIMM8_INTRINSIC
       <"v2maxsi", 0x4, 0x12, 0x3, 0x2B, int_tilegx_v2maxsi>;
defm V2MINS_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v2mins", 0x5, 0x82, 0x5, 0x54, int_tilegx_v2mins>;
defm V2MINSI_INTRINSIC
     : TileVBINIMM8_INTRINSIC
       <"v2minsi", 0x4, 0x13, 0x3, 0x2C, int_tilegx_v2minsi>;
defm V2MNZ_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v2mnz", 0x5, 0x83, 0x5, 0x55, int_tilegx_v2mnz>;
defm V2MULFSC_INTRINSIC
     : TileVBINRRR_X0_INTRINSIC
       <"v2mulfsc", 0x5, 0x84, int_tilegx_v2mulfsc>;
defm V2MULS_INTRINSIC
     : TileVBINRRR_X0_INTRINSIC
       <"v2muls", 0x5, 0x85, int_tilegx_v2muls>;
defm V2MULTS_INTRINSIC
     : TileVBINRRR_X0_INTRINSIC
       <"v2mults", 0x5, 0x86, int_tilegx_v2mults>;
defm V2MZ_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v2mults", 0x5, 0x87, 0x5, 0x56, int_tilegx_v2mults>;
defm V2PACKH_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v2packh", 0x5, 0x88, 0x5, 0x57, int_tilegx_v2packh>;
defm V2PACKL_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v2packl", 0x5, 0x89, 0x5, 0x58, int_tilegx_v2packl>;
defm V2PACKUC_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v2packuc", 0x5, 0x8A, 0x5, 0x59, int_tilegx_v2packuc>;
defm V2SADAS_INTRINSIC
     : TileVBINRRR_X0_INTRINSIC
       <"v2sadas", 0x5, 0x8B, int_tilegx_v2sadas>;
defm V2SADAU_INTRINSIC
     : TileVBINRRR_X0_INTRINSIC
       <"v2sadau", 0x5, 0x8C, int_tilegx_v2sadau>;
defm V2SADS_INTRINSIC
     : TileVBINRRR_X0_INTRINSIC
       <"v2sads", 0x5, 0x8D, int_tilegx_v2sads>;
defm V2SADU_INTRINSIC
     : TileVBINRRR_X0_INTRINSIC
       <"v2sadu", 0x5, 0x8E, int_tilegx_v2sadu>;
defm V2SHL_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v2shl", 0x5, 0x90, 0x5, 0x5B, int_tilegx_v2shl>;
defm V2SHLI_INTRINSIC
     : TileVBINSHIFT_INTRINSIC
       <"v2shli", 0x6, 0xA, 0x6, 0xA, int_tilegx_v2shli>;
defm V2SHLSC_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v2shlsc", 0x5, 0x8F, 0x5, 0x5A, int_tilegx_v2shlsc>;
defm V2SHRS_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v2shrs", 0x5, 0x91, 0x5, 0x5C, int_tilegx_v2shrs>;
defm V2SHRSI_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v2shrsi", 0x6, 0xB, 0x6, 0xB, int_tilegx_v2shrsi>;
defm V2SHRU_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v2shru", 0x5, 0x92, 0x5, 0x5D, int_tilegx_v2shru>;
defm V2SHRUI_INTRINSIC
     : TileVBINSHIFT_INTRINSIC
       <"v2shrui", 0x6, 0xC, 0x6, 0xC, int_tilegx_v2shrui>;
defm V2SUB_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v2sub", 0x5, 0x94, 0x5, 0x5F, int_tilegx_v2sub>;
defm V2SUBSC_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v2subsc", 0x5, 0x93, 0x5, 0x5E, int_tilegx_v2subsc>;

// 2 x 32bit SIMD
defm V4ADD_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v4add", 0x5, 0x96, 0x5, 0x61, int_tilegx_v4add>;
defm V4ADDSC_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v4addsc", 0x5, 0x95, 0x5, 0x60, int_tilegx_v4addsc>;
defm V4INT_H_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v4int_h", 0x5, 0x97, 0x5, 0x62, int_tilegx_v4int_h>;
defm V4INT_L_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v4int_l", 0x5, 0x98, 0x5, 0x63, int_tilegx_v4int_l>;
defm V4PACKSC_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v4packsc", 0x5, 0x99, 0x5, 0x64, int_tilegx_v4packsc>;
defm V4SHL_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v4shl", 0x5, 0x9B, 0x5, 0x66, int_tilegx_v4shl>;
defm V4SHLSC_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v4shlsc", 0x5, 0x9A, 0x5, 0x65, int_tilegx_v4shlsc>;
defm V4SHRS_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v4shrs", 0x5, 0x9C, 0x5, 0x67, int_tilegx_v4shrs>;
defm V4SHRU_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v4shru", 0x5, 0x9D, 0x5, 0x68, int_tilegx_v4shru>;
defm V4SUB_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v4sub", 0x5, 0x9F, 0x5, 0x6A, int_tilegx_v4sub>;
defm V4SUBSC_INTRINSIC
     : TileVBINRRR_INTRINSIC
       <"v4subsc", 0x5, 0x9E, 0x5, 0x69, int_tilegx_v4subsc>;

//===------------------- Auto-Vectorize Support ----------------------===//

multiclass TileVADD<ValueType Ty, string OpStr,
                    bits<3>op_x0, bits<10>subop_x0,
                    bits<3>op_x1, bits<10>subop_x1> {

  def #NAME#
      : TileInstX1RRR
        <op_x1, subop_x1,
         (outs SIMDRegs:$rd),
         (ins SIMDRegs:$rsa, SIMDRegs:$rsb),
         !strconcat(OpStr, "\t$rd, $rsa, $rsb"),
         [(set (Ty SIMDRegs:$rd),
            (add SIMDRegs:$rsa, SIMDRegs:$rsb))],
         IIC_SIMD, FrmRRR, S_X0_X1>;

  def #0_X0#
      : TileBundleX0RRR
        <op_x0, subop_x0,
         (outs SIMDRegs:$rd),
         (ins SIMDRegs:$rsa, SIMDRegs:$rsb),
         !strconcat(OpStr, "\t$rd, $rsa, $rsb"),
         [],
         IIC_SIMD, FrmRRR, S_X0_X1>;

  def #0_X1#
      : TileBundleX1RRR
        <op_x1, subop_x1,
         (outs SIMDRegs:$rd),
         (ins SIMDRegs:$rsa, SIMDRegs:$rsb),
         !strconcat(OpStr, "\t$rd, $rsa, $rsb"),
         [],
         IIC_SIMD, FrmRRR, S_X0_X1>;
}

multiclass TileVSUB<ValueType Ty, string OpStr,
                    bits<3>op_x0, bits<10>subop_x0,
                    bits<3>op_x1, bits<10>subop_x1> {

  def #NAME#
      : TileInstX1RRR
        <op_x1, subop_x1,
         (outs SIMDRegs:$rd),
         (ins SIMDRegs:$rsa, SIMDRegs:$rsb),
         !strconcat(OpStr, "\t$rd, $rsa, $rsb"),
         [(set (Ty SIMDRegs:$rd),
            (sub SIMDRegs:$rsa, SIMDRegs:$rsb))],
         IIC_SIMD, FrmRRR, S_X0_X1>;

  def #0_X0#
      : TileBundleX0RRR
        <op_x0, subop_x0,
         (outs SIMDRegs:$rd),
         (ins SIMDRegs:$rsa, SIMDRegs:$rsb),
         !strconcat(OpStr, "\t$rd, $rsa, $rsb"),
         [],
         IIC_SIMD, FrmRRR, S_X0_X1>;

  def #0_X1#
      : TileBundleX1RRR
        <op_x1, subop_x1,
         (outs SIMDRegs:$rd),
         (ins SIMDRegs:$rsa, SIMDRegs:$rsb),
         !strconcat(OpStr, "\t$rd, $rsa, $rsb"),
         [],
         IIC_SIMD, FrmRRR, S_X0_X1>;
}

defm V1ADD    : TileVADD<v8i8, "v1add", 0x5, 0x54, 0x5, 0x37>;
defm V2ADD    : TileVADD<v4i16, "v2add", 0x5, 0x74, 0x5, 0x4A>;
defm V4ADD    : TileVADD<v2i32, "v4add", 0x5, 0x96, 0x5, 0x61>;

defm V1SUB    : TileVSUB<v8i8, "v1sub", 0x5, 0x72, 0x5, 0x48>;
defm V2SUB    : TileVSUB<v4i16, "v2sub", 0x5, 0x94, 0x5, 0x5F>;
defm V4SUB    : TileVSUB<v2i32, "v4sub", 0x5, 0x9F, 0x5, 0x6A>;

def : Pat<(v8i8 (bitconvert (i64 CPURegs:$src))),
           (COPY_TO_REGCLASS CPURegs:$src, SIMDRegs)>;

def : Pat<(v4i16 (bitconvert (i64 CPURegs:$src))),
           (COPY_TO_REGCLASS CPURegs:$src, SIMDRegs)>;

def : Pat<(v2i32 (bitconvert (i64 CPURegs:$src))),
           (COPY_TO_REGCLASS CPURegs:$src, SIMDRegs)>;

def : Pat<(i64 (bitconvert (v8i8 SIMDRegs:$src))),
           (COPY_TO_REGCLASS SIMDRegs:$src, CPURegs)>;

def : Pat<(i64 (bitconvert (v4i16 SIMDRegs:$src))),
           (COPY_TO_REGCLASS SIMDRegs:$src, CPURegs)>;

def : Pat<(i64 (bitconvert (v2i32 SIMDRegs:$src))),
           (COPY_TO_REGCLASS SIMDRegs:$src, CPURegs)>;
