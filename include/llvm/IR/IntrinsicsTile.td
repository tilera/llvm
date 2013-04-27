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

// v1XXX
def int_tilegx_v1add : GCCBuiltin<"__builtin_tilegx_v1add">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], [Commutative]>;

def int_tilegx_v1addi : GCCBuiltin<"__builtin_tilegx_v1addi">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1adduc : GCCBuiltin<"__builtin_tilegx_v1adduc">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1adiffu : GCCBuiltin<"__builtin_tilegx_v1adiffu">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1avgu : GCCBuiltin<"__builtin_tilegx_v1avgu">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1cmpeq : GCCBuiltin<"__builtin_tilegx_v1cmpeq">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1cmpeqi : GCCBuiltin<"__builtin_tilegx_v1cmpeqi">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1cmples : GCCBuiltin<"__builtin_tilegx_v1cmples">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1cmpleu : GCCBuiltin<"__builtin_tilegx_v1cmpleu">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1cmplts : GCCBuiltin<"__builtin_tilegx_v1cmplts">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1cmpltsi : GCCBuiltin<"__builtin_tilegx_v1cmpltsi">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1cmpltu : GCCBuiltin<"__builtin_tilegx_v1cmpltu">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1cmpltui : GCCBuiltin<"__builtin_tilegx_v1cmpltui">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1cmpne : GCCBuiltin<"__builtin_tilegx_v1cmpne">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1ddotpu : GCCBuiltin<"__builtin_tilegx_v1ddotpu">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1ddotpua : GCCBuiltin<"__builtin_tilegx_v1ddotpua">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1ddotpus : GCCBuiltin<"__builtin_tilegx_v1ddotpus">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1ddotpusa : GCCBuiltin<"__builtin_tilegx_v1ddotpusa">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1dotp : GCCBuiltin<"__builtin_tilegx_v1dotp">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1dotpa : GCCBuiltin<"__builtin_tilegx_v1dotpa">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1dotpu : GCCBuiltin<"__builtin_tilegx_v1dotpu">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1dotpua : GCCBuiltin<"__builtin_tilegx_v1dotpua">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1dotpus : GCCBuiltin<"__builtin_tilegx_v1dotpus">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1dotpusa : GCCBuiltin<"__builtin_tilegx_v1dotpusa">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1int_h : GCCBuiltin<"__builtin_tilegx_v1int_h">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1int_l : GCCBuiltin<"__builtin_tilegx_v1int_l">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1maxu : GCCBuiltin<"__builtin_tilegx_v1maxu">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1maxui : GCCBuiltin<"__builtin_tilegx_v1maxui">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1minu : GCCBuiltin<"__builtin_tilegx_v1minu">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1minui : GCCBuiltin<"__builtin_tilegx_v1minui">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1mnz : GCCBuiltin<"__builtin_tilegx_v1mnz">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1multu : GCCBuiltin<"__builtin_tilegx_v1multu">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1mulu : GCCBuiltin<"__builtin_tilegx_v1mulu">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1mulus : GCCBuiltin<"__builtin_tilegx_v1mulus">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1mz : GCCBuiltin<"__builtin_tilegx_v1mz">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1sadau : GCCBuiltin<"__builtin_tilegx_v1sadau">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1sadu : GCCBuiltin<"__builtin_tilegx_v1sadu">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1shl : GCCBuiltin<"__builtin_tilegx_v1shl">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1shli : GCCBuiltin<"__builtin_tilegx_v1shli">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1shrs : GCCBuiltin<"__builtin_tilegx_v1shrs">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1shrsi : GCCBuiltin<"__builtin_tilegx_v1shrsi">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1shru : GCCBuiltin<"__builtin_tilegx_v1shru">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1shrui : GCCBuiltin<"__builtin_tilegx_v1shrui">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1sub : GCCBuiltin<"__builtin_tilegx_v1sub">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1subuc : GCCBuiltin<"__builtin_tilegx_v1subuc">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

// v2XXX
def int_tilegx_v2add : GCCBuiltin<"__builtin_tilegx_v2add">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], [Commutative]>;

def int_tilegx_v2addi : GCCBuiltin<"__builtin_tilegx_v2addi">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2addsc : GCCBuiltin<"__builtin_tilegx_v2addsc">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2adiffs : GCCBuiltin<"__builtin_tilegx_v2adiffs">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2avgs : GCCBuiltin<"__builtin_tilegx_v2avgs">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2cmpeq : GCCBuiltin<"__builtin_tilegx_v2cmpeq">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2cmpeqi : GCCBuiltin<"__builtin_tilegx_v2cmpeqi">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2cmples : GCCBuiltin<"__builtin_tilegx_v2cmples">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2cmpleu : GCCBuiltin<"__builtin_tilegx_v2cmpleu">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2cmplts : GCCBuiltin<"__builtin_tilegx_v2cmplts">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2cmpltsi : GCCBuiltin<"__builtin_tilegx_v2cmpltsi">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2cmpltu : GCCBuiltin<"__builtin_tilegx_v2cmpltu">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2cmpltui : GCCBuiltin<"__builtin_tilegx_v2cmpltui">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2cmpne : GCCBuiltin<"__builtin_tilegx_v2cmpne">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2dotp : GCCBuiltin<"__builtin_tilegx_v2dotp">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2dotpa : GCCBuiltin<"__builtin_tilegx_v2dotpa">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2int_h : GCCBuiltin<"__builtin_tilegx_v2int_h">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2int_l : GCCBuiltin<"__builtin_tilegx_v2int_l">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2maxs : GCCBuiltin<"__builtin_tilegx_v2maxs">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2maxsi : GCCBuiltin<"__builtin_tilegx_v2maxsi">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2mins : GCCBuiltin<"__builtin_tilegx_v2mins">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2minsi : GCCBuiltin<"__builtin_tilegx_v2minsi">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2mnz : GCCBuiltin<"__builtin_tilegx_v2mnz">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2mulfsc : GCCBuiltin<"__builtin_tilegx_v2mulfsc">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2muls : GCCBuiltin<"__builtin_tilegx_v2muls">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2mults : GCCBuiltin<"__builtin_tilegx_v2mults">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2mz : GCCBuiltin<"__builtin_tilegx_v2mz">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2packh : GCCBuiltin<"__builtin_tilegx_v2packh">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2packl : GCCBuiltin<"__builtin_tilegx_v2packl">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2packuc : GCCBuiltin<"__builtin_tilegx_v2packuc">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2sadas : GCCBuiltin<"__builtin_tilegx_v2sadas">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2sadau : GCCBuiltin<"__builtin_tilegx_v2sadau">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2sads : GCCBuiltin<"__builtin_tilegx_v2sads">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2sadu : GCCBuiltin<"__builtin_tilegx_v2sadu">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2shl : GCCBuiltin<"__builtin_tilegx_v2shl">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2shli : GCCBuiltin<"__builtin_tilegx_v2shli">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2shlsc : GCCBuiltin<"__builtin_tilegx_v2shlsc">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2shrs : GCCBuiltin<"__builtin_tilegx_v2shrs">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2shrsi : GCCBuiltin<"__builtin_tilegx_v2shrsi">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2shru : GCCBuiltin<"__builtin_tilegx_v2shru">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2shrui : GCCBuiltin<"__builtin_tilegx_v2shrui">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2sub : GCCBuiltin<"__builtin_tilegx_v2sub">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2subsc : GCCBuiltin<"__builtin_tilegx_v2subsc">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

// v4XXX
def int_tilegx_v4add : GCCBuiltin<"__builtin_tilegx_v4add">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], [Commutative]>;

def int_tilegx_v4addsc : GCCBuiltin<"__builtin_tilegx_v4addsc">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v4int_h : GCCBuiltin<"__builtin_tilegx_v4int_h">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v4int_l : GCCBuiltin<"__builtin_tilegx_v4int_l">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v4packsc : GCCBuiltin<"__builtin_tilegx_v4packsc">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v4shl : GCCBuiltin<"__builtin_tilegx_v4shl">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v4shlsc : GCCBuiltin<"__builtin_tilegx_v4shlsc">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v4shrs : GCCBuiltin<"__builtin_tilegx_v4shrs">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v4shru : GCCBuiltin<"__builtin_tilegx_v4shru">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v4sub : GCCBuiltin<"__builtin_tilegx_v4sub">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v4subsc : GCCBuiltin<"__builtin_tilegx_v4subsc">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;
} // end TargetPrefix
