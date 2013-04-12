//===-- TileCallingConv.td - Calling Conventions for Tile --*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
// This describes the calling conventions for Tile architecture.
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Tile Calling Convention
//===----------------------------------------------------------------------===//

def CC_Tile : CallingConv<[
   // Handles byval parameters.
  CCIfByVal<CCCustom<"CC_TileByval">>,

  // Promote i8/i16 arguments to i32.
  CCIfType<[i8, i16], CCPromoteToType<i32>>,

  // Integer arguments are passed in integer registers.
  CCIfType<[i32, f32], CCAssignToReg<[R0_32, R1_32, R2_32, R3_32, R4_32,
                                      R5_32, R6_32, R7_32, R8_32, R9_32]>>,

  CCIfType<[i64, f64], CCAssignToReg<[R0, R1, R2, R3, R4,
                                      R5, R6, R7, R8, R9]>>,

  // All stack parameter slots become 64-bit doublewords and are 8-byte aligned.
  CCIfType<[i32, i64, f32, f64], CCCustom<"CC_Tile_StackArg">>
]>;

def RetCC_Tile : CallingConv<[
  // i32 are returned in registers R[0-9]_32.
  CCIfType<[i32, f32], CCAssignToReg<[R0_32, R1_32, R2_32, R3_32, R4_32,
                                      R5_32, R6_32, R7_32, R8_32, R9_32]>>,

  // i64 are returned in registers R[0-9].
  CCIfType<[i64, f64], CCAssignToReg<[R0, R1, R2, R3, R4,
                                      R5, R6, R7, R8, R9]>>
]>;

//===----------------------------------------------------------------------===//
// Callee-saved register lists.
//===----------------------------------------------------------------------===//

// For lp, gp, fp, lr, sp, we will handle them manully in pro/epi hooks.
def CSR_Tile : CalleeSavedRegs<(add (sequence "R%u", 49, 30), R50, R51, FP)>;
