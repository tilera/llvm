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

multiclass TileFSINGLE_ADD1 {

  def #NAME#
      : TileInstX0RRR
        <0x5, 0x22,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "fsingle_add1\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x22,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "fsingle_add1\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;
}

multiclass TileFSINGLE_SUB1 {

  def #NAME#
      : TileInstX0RRR
        <0x5, 0x27,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "fsingle_sub1\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x27,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "fsingle_sub1\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;
}

let Constraints = "$rd = $rsc" in
multiclass TileFSINGLE_ADDSUB2 {

  def #NAME#
      : TileInstX0RRR
        <0x5, 0x23,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb, CPU32Regs:$rsc),
         "fsingle_addsub2\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x23,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb, CPU32Regs:$rsc),
         "fsingle_addsub2\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;
}

multiclass TileFSINGLE_MUL1 {

  def #NAME#
      : TileInstX0RRR
        <0x5, 0x24,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "fsingle_mul1\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x24,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "fsingle_mul1\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;
}

multiclass TileFSINGLE_MUL2 {

  def #NAME#
      : TileInstX0RRR
        <0x5, 0x25,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "fsingle_mul2\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x25,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "fsingle_mul2\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;
}

multiclass TileFSINGLE_PACK1 {

  def #NAME#
      : TileInstX0Unary
        <0x5, 0x52, 0x4,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rs),
         "fsingle_pack1\t$rd, $rs",
         [],
         IIC_MUL, FrmRRR, S_X0_Y0>;

  def #0_X0#
      : TileBundleX0Unary
        <0x5, 0x52, 0x4,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rs),
         "fsingle_pack1\t$rd, $rs",
         [],
         IIC_MUL, FrmRRR, S_X0_Y0>;

  def #0_Y0#
      : TileBundleY0Unary
        <0x6, 0x3, 0x4,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rs),
         "fsingle_pack1\t$rd, $rs",
         [],
         IIC_MUL, FrmRRR, S_X0_Y0>;

  def #64#
      : TileInstX0Unary
        <0x5, 0x52, 0x4,
         (outs CPURegs:$rd),
         (ins CPURegs:$rs),
         "fsingle_pack1\t$rd, $rs",
         [],
         IIC_MUL, FrmRRR, S_X0_Y0>;
}

multiclass TileFSINGLE_PACK2 {

  def #NAME#
      : TileInstX0RRR
        <0x5, 0x26,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "fsingle_pack2\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x26,
         (outs CPU32Regs:$rd),
         (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
         "fsingle_pack2\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;

  def #32_64#
      : TileInstX0RRR
        <0x5, 0x26,
         (outs CPU32Regs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "fsingle_pack2\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;
}

multiclass TileFDOUBLE_PACK1 {

  def #NAME#
      : TileInstX0RRR
        <0x5, 0x1D,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "fdouble_pack1\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x1D,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "fdouble_pack1\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;
}

let Constraints = "$rd = $rsc" in
multiclass TileFDOUBLE_PACK2 {

  def #NAME#
      : TileInstX0RRR
        <0x5, 0x1E,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb, CPURegs:$rsc),
         "fdouble_pack2\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x1E,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb, CPURegs:$rsc),
         "fdouble_pack2\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;
}

let Constraints = "$rd = $rsc" in
multiclass TileFDOUBLE_ADDSUB {

  def #NAME#
      : TileInstX0RRR
        <0x5, 0x1A,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb, CPURegs:$rsc),
         "fdouble_addsub\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x1A,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb, CPURegs:$rsc),
         "fdouble_addsub\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;
}

multiclass TileFDOUBLE_MUL_FLAGS {

  def #NAME#
      : TileInstX0RRR
        <0x5, 0x1C,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "fdouble_mul_flags\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x1C,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "fdouble_mul_flags\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;
}

multiclass TileFDOUBLE_ADD_FLAGS {

  def #NAME#
      : TileInstX0RRR
        <0x5, 0x1B,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "fdouble_add_flags\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x1B,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "fdouble_add_flags\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;
}

multiclass TileFDOUBLE_SUB_FLAGS {

  def #NAME#
      : TileInstX0RRR
        <0x5, 0x1F,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "fdouble_sub_flags\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x1F,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "fdouble_sub_flags\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;
}

multiclass TileFDOUBLE_UNPACK_MAX {

  def #NAME#
      : TileInstX0RRR
        <0x5, 0x20,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "fdouble_unpack_max\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x20,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "fdouble_unpack_max\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;
}

multiclass TileFDOUBLE_UNPACK_MIN {

  def #NAME#
      : TileInstX0RRR
        <0x5, 0x21,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "fdouble_unpack_min\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;

  def #0_X0#
      : TileBundleX0RRR
        <0x5, 0x21,
         (outs CPURegs:$rd),
         (ins CPURegs:$rsa, CPURegs:$rsb),
         "fdouble_unpack_min\t$rd, $rsa, $rsb",
         [],
         IIC_MUL, FrmRRR, S_X0>;
}

def FSINGLE_CMP_OLT
    : TilePseudo
      <(outs CPU32Regs:$rd),
       (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
       "#fsingle_cmp_olt",
       [(set (i32 CPU32Regs:$rd),
          (setolt (f32 CPU32Regs:$rsa), CPU32Regs:$rsb))],
       IIC_MUL>;

def FSINGLE_CMP_ULT
    : TilePseudo
      <(outs CPU32Regs:$rd),
       (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
       "#fsingle_cmp_ult",
       [(set (i32 CPU32Regs:$rd),
          (setult (f32 CPU32Regs:$rsa), CPU32Regs:$rsb))],
       IIC_MUL>;

def FDOUBLE_CMP_OLT
    : TilePseudo
      <(outs CPU32Regs:$rd),
       (ins CPURegs:$rsa, CPURegs:$rsb),
       "#fdouble_cmp_olt",
       [(set (i32 CPU32Regs:$rd),
          (setolt (f64 CPURegs:$rsa), CPURegs:$rsb))],
       IIC_MUL>;

def FDOUBLE_CMP_ULT
    : TilePseudo
      <(outs CPU32Regs:$rd),
       (ins CPURegs:$rsa, CPURegs:$rsb),
       "#fdouble_cmp_ult",
       [(set (i32 CPU32Regs:$rd),
          (setult (f64 CPURegs:$rsa), CPURegs:$rsb))],
       IIC_MUL>;

def FSINGLE_CMP_OLE
    : TilePseudo
      <(outs CPU32Regs:$rd),
       (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
       "#fsingle_cmp_ole",
       [(set (i32 CPU32Regs:$rd),
          (setole (f32 CPU32Regs:$rsa), CPU32Regs:$rsb))],
       IIC_MUL>;

def FSINGLE_CMP_ULE
    : TilePseudo
      <(outs CPU32Regs:$rd),
       (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
       "#fsingle_cmp_ule",
       [(set (i32 CPU32Regs:$rd),
          (setule (f32 CPU32Regs:$rsa), CPU32Regs:$rsb))],
       IIC_MUL>;

def FDOUBLE_CMP_OLE
    : TilePseudo
      <(outs CPU32Regs:$rd),
       (ins CPURegs:$rsa, CPURegs:$rsb),
       "#fdouble_cmp_ole",
       [(set (i32 CPU32Regs:$rd),
          (setole (f64 CPURegs:$rsa), CPURegs:$rsb))],
       IIC_MUL>;

def FDOUBLE_CMP_ULE
    : TilePseudo
      <(outs CPU32Regs:$rd),
       (ins CPURegs:$rsa, CPURegs:$rsb),
       "#fdouble_cmp_ule",
       [(set (i32 CPU32Regs:$rd),
          (setule (f64 CPURegs:$rsa), CPURegs:$rsb))],
       IIC_MUL>;

def FSINGLE_CMP_OGT
    : TilePseudo
      <(outs CPU32Regs:$rd),
       (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
       "#fsingle_cmp_ogt",
       [(set (i32 CPU32Regs:$rd),
          (setogt (f32 CPU32Regs:$rsa), CPU32Regs:$rsb))],
       IIC_MUL>;

def FSINGLE_CMP_UGT
    : TilePseudo
      <(outs CPU32Regs:$rd),
       (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
       "#fsingle_cmp_ugt",
       [(set (i32 CPU32Regs:$rd),
          (setugt (f32 CPU32Regs:$rsa), CPU32Regs:$rsb))],
       IIC_MUL>;

def FDOUBLE_CMP_OGT
    : TilePseudo
      <(outs CPU32Regs:$rd),
       (ins CPURegs:$rsa, CPURegs:$rsb),
       "#fdouble_cmp_ogt",
       [(set (i32 CPU32Regs:$rd),
          (setogt (f64 CPURegs:$rsa), CPURegs:$rsb))],
       IIC_MUL>;

def FDOUBLE_CMP_UGT
    : TilePseudo
      <(outs CPU32Regs:$rd),
       (ins CPURegs:$rsa, CPURegs:$rsb),
       "#fdouble_cmp_ugt",
       [(set (i32 CPU32Regs:$rd),
          (setugt (f64 CPURegs:$rsa), CPURegs:$rsb))],
       IIC_MUL>;

def FSINGLE_CMP_OGE
    : TilePseudo
      <(outs CPU32Regs:$rd),
       (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
       "#fsingle_cmp_oge",
       [(set (i32 CPU32Regs:$rd),
          (setoge (f32 CPU32Regs:$rsa), CPU32Regs:$rsb))],
       IIC_MUL>;

def FSINGLE_CMP_UGE
    : TilePseudo
      <(outs CPU32Regs:$rd),
       (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
       "#fsingle_cmp_uge",
       [(set (i32 CPU32Regs:$rd),
          (setuge (f32 CPU32Regs:$rsa), CPU32Regs:$rsb))],
       IIC_MUL>;

def FDOUBLE_CMP_OGE
    : TilePseudo
      <(outs CPU32Regs:$rd),
       (ins CPURegs:$rsa, CPURegs:$rsb),
       "#fdouble_cmp_oge",
       [(set (i32 CPU32Regs:$rd),
          (setoge (f64 CPURegs:$rsa), CPURegs:$rsb))],
       IIC_MUL>;

def FDOUBLE_CMP_UGE
    : TilePseudo
      <(outs CPU32Regs:$rd),
       (ins CPURegs:$rsa, CPURegs:$rsb),
       "#fdouble_cmp_uge",
       [(set (i32 CPU32Regs:$rd),
          (setuge (f64 CPURegs:$rsa), CPURegs:$rsb))],
       IIC_MUL>;

def FSINGLE_CMP_OEQ
    : TilePseudo
      <(outs CPU32Regs:$rd),
       (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
       "#fsingle_cmp_oeq",
       [(set (i32 CPU32Regs:$rd),
          (setoeq (f32 CPU32Regs:$rsa), CPU32Regs:$rsb))],
       IIC_MUL>;

def FSINGLE_CMP_UEQ
    : TilePseudo
      <(outs CPU32Regs:$rd),
       (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
       "#fsingle_cmp_ueq",
       [(set (i32 CPU32Regs:$rd),
          (setueq (f32 CPU32Regs:$rsa), CPU32Regs:$rsb))],
       IIC_MUL>;

def FDOUBLE_CMP_OEQ
    : TilePseudo
      <(outs CPU32Regs:$rd),
       (ins CPURegs:$rsa, CPURegs:$rsb),
       "#fdouble_cmp_oeq",
       [(set (i32 CPU32Regs:$rd),
          (setoeq (f64 CPURegs:$rsa), CPURegs:$rsb))],
       IIC_MUL>;

def FDOUBLE_CMP_UEQ
    : TilePseudo
      <(outs CPU32Regs:$rd),
       (ins CPURegs:$rsa, CPURegs:$rsb),
       "#fdouble_cmp_ueq",
       [(set (i32 CPU32Regs:$rd),
          (setueq (f64 CPURegs:$rsa), CPURegs:$rsb))],
       IIC_MUL>;

def FSINGLE_CMP_ONE
    : TilePseudo
      <(outs CPU32Regs:$rd),
       (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
       "#fsingle_cmp_one",
       [(set (i32 CPU32Regs:$rd),
          (setone (f32 CPU32Regs:$rsa), CPU32Regs:$rsb))],
       IIC_MUL>;

def FSINGLE_CMP_UNE
    : TilePseudo
      <(outs CPU32Regs:$rd),
       (ins CPU32Regs:$rsa, CPU32Regs:$rsb),
       "#fsingle_cmp_une",
       [(set (i32 CPU32Regs:$rd),
          (setune (f32 CPU32Regs:$rsa), CPU32Regs:$rsb))],
       IIC_MUL>;

def FDOUBLE_CMP_ONE
    : TilePseudo
      <(outs CPU32Regs:$rd),
       (ins CPURegs:$rsa, CPURegs:$rsb),
       "#fdouble_cmp_one",
       [(set (i32 CPU32Regs:$rd),
          (setone (f64 CPURegs:$rsa), CPURegs:$rsb))],
       IIC_MUL>;

def FDOUBLE_CMP_UNE
    : TilePseudo
      <(outs CPU32Regs:$rd),
       (ins CPURegs:$rsa, CPURegs:$rsb),
       "#fdouble_cmp_une",
       [(set (i32 CPU32Regs:$rd),
          (setune (f64 CPURegs:$rsa), CPURegs:$rsb))],
       IIC_MUL>;

def : Pat<(i32 (bitconvert (f32 CPU32Regs:$src))),
           (COPY_TO_REGCLASS CPU32Regs:$src, CPU32Regs)>;
def : Pat<(i64 (bitconvert (f64 CPURegs:$src))),
           (COPY_TO_REGCLASS CPURegs:$src, CPURegs)>;
def : Pat<(f32 (bitconvert (i32 CPU32Regs:$src))),
           (COPY_TO_REGCLASS CPU32Regs:$src, CPU32Regs)>;
def : Pat<(f64 (bitconvert (i64 CPURegs:$src))),
           (COPY_TO_REGCLASS CPURegs:$src, CPURegs)>;

defm FSINGLE_ADD1  : TileFSINGLE_ADD1;
defm FSINGLE_SUB1  : TileFSINGLE_SUB1;
defm FSINGLE_MUL1  : TileFSINGLE_MUL1;
defm FSINGLE_MUL2  : TileFSINGLE_MUL2;
defm FSINGLE_PACK1 : TileFSINGLE_PACK1;
defm FSINGLE_PACK2 : TileFSINGLE_PACK2;
defm FSINGLE_ADDSUB2 : TileFSINGLE_ADDSUB2;
defm FDOUBLE_PACK1 : TileFDOUBLE_PACK1;
defm FDOUBLE_PACK2 : TileFDOUBLE_PACK2;
defm FDOUBLE_ADDSUB  : TileFDOUBLE_ADDSUB;
defm FDOUBLE_MUL_FLAGS  : TileFDOUBLE_MUL_FLAGS;
defm FDOUBLE_ADD_FLAGS  : TileFDOUBLE_ADD_FLAGS;
defm FDOUBLE_SUB_FLAGS  : TileFDOUBLE_SUB_FLAGS;
defm FDOUBLE_UNPACK_MIN : TileFDOUBLE_UNPACK_MIN;
defm FDOUBLE_UNPACK_MAX : TileFDOUBLE_UNPACK_MAX;
