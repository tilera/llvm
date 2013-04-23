//===- IntrinsicsTile.td - Defines TILE-Gx intrinsics ---------*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines all of the TILE-Gx intrinsics.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//

let TargetPrefix = "tilegx" in {  // All intrinsics start with "llvm.tilegx.".

// ADD
def int_tilegx_v1add : GCCBuiltin<"__builtin_tilegx_v1add">,
  Intrinsic<[llvm_v8i8_ty], [llvm_v8i8_ty, llvm_v8i8_ty], [Commutative]>;

def int_tilegx_v2add : GCCBuiltin<"__builtin_tilegx_v2add">,
  Intrinsic<[llvm_v4i16_ty], [llvm_v4i16_ty, llvm_v4i16_ty], [Commutative]>;

def int_tilegx_v4add : GCCBuiltin<"__builtin_tilegx_v4add">,
  Intrinsic<[llvm_v2i32_ty], [llvm_v2i32_ty, llvm_v2i32_ty], [Commutative]>;

// SUB
def int_tilegx_v1sub : GCCBuiltin<"__builtin_tilegx_v1sub">,
  Intrinsic<[llvm_v8i8_ty], [llvm_v8i8_ty, llvm_v8i8_ty], []>;

def int_tilegx_v2sub : GCCBuiltin<"__builtin_tilegx_v2sub">,
  Intrinsic<[llvm_v4i16_ty], [llvm_v4i16_ty, llvm_v4i16_ty], []>;

def int_tilegx_v4sub : GCCBuiltin<"__builtin_tilegx_v4sub">,
  Intrinsic<[llvm_v2i32_ty], [llvm_v2i32_ty, llvm_v2i32_ty], []>;
} // end TargetPrefix
