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
def int_tilegx_v1add : GCCBuiltin<"__insn_v1add">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], [Commutative]>;

def int_tilegx_v1addi : GCCBuiltin<"__insn_v1addi">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1adduc : GCCBuiltin<"__insn_v1adduc">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1adiffu : GCCBuiltin<"__insn_v1adiffu">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1avgu : GCCBuiltin<"__insn_v1avgu">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1cmpeq : GCCBuiltin<"__insn_v1cmpeq">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1cmpeqi : GCCBuiltin<"__insn_v1cmpeqi">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1cmples : GCCBuiltin<"__insn_v1cmples">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1cmpleu : GCCBuiltin<"__insn_v1cmpleu">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1cmplts : GCCBuiltin<"__insn_v1cmplts">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1cmpltsi : GCCBuiltin<"__insn_v1cmpltsi">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1cmpltu : GCCBuiltin<"__insn_v1cmpltu">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1cmpltui : GCCBuiltin<"__insn_v1cmpltui">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1cmpne : GCCBuiltin<"__insn_v1cmpne">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1ddotpu : GCCBuiltin<"__insn_v1ddotpu">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1ddotpua : GCCBuiltin<"__insn_v1ddotpua">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1ddotpus : GCCBuiltin<"__insn_v1ddotpus">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1ddotpusa : GCCBuiltin<"__insn_v1ddotpusa">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1dotp : GCCBuiltin<"__insn_v1dotp">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1dotpa : GCCBuiltin<"__insn_v1dotpa">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1dotpu : GCCBuiltin<"__insn_v1dotpu">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1dotpua : GCCBuiltin<"__insn_v1dotpua">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1dotpus : GCCBuiltin<"__insn_v1dotpus">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1dotpusa : GCCBuiltin<"__insn_v1dotpusa">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1int_h : GCCBuiltin<"__insn_v1int_h">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1int_l : GCCBuiltin<"__insn_v1int_l">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1maxu : GCCBuiltin<"__insn_v1maxu">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1maxui : GCCBuiltin<"__insn_v1maxui">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1minu : GCCBuiltin<"__insn_v1minu">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1minui : GCCBuiltin<"__insn_v1minui">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1mnz : GCCBuiltin<"__insn_v1mnz">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1multu : GCCBuiltin<"__insn_v1multu">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1mulu : GCCBuiltin<"__insn_v1mulu">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1mulus : GCCBuiltin<"__insn_v1mulus">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1mz : GCCBuiltin<"__insn_v1mz">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1sadau : GCCBuiltin<"__insn_v1sadau">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1sadu : GCCBuiltin<"__insn_v1sadu">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1shl : GCCBuiltin<"__insn_v1shl">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1shli : GCCBuiltin<"__insn_v1shli">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1shrs : GCCBuiltin<"__insn_v1shrs">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1shrsi : GCCBuiltin<"__insn_v1shrsi">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1shru : GCCBuiltin<"__insn_v1shru">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1shrui : GCCBuiltin<"__insn_v1shrui">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1sub : GCCBuiltin<"__insn_v1sub">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v1subuc : GCCBuiltin<"__insn_v1subuc">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

// v2XXX
def int_tilegx_v2add : GCCBuiltin<"__insn_v2add">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], [Commutative]>;

def int_tilegx_v2addi : GCCBuiltin<"__insn_v2addi">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2addsc : GCCBuiltin<"__insn_v2addsc">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2adiffs : GCCBuiltin<"__insn_v2adiffs">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2avgs : GCCBuiltin<"__insn_v2avgs">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2cmpeq : GCCBuiltin<"__insn_v2cmpeq">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2cmpeqi : GCCBuiltin<"__insn_v2cmpeqi">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2cmples : GCCBuiltin<"__insn_v2cmples">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2cmpleu : GCCBuiltin<"__insn_v2cmpleu">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2cmplts : GCCBuiltin<"__insn_v2cmplts">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2cmpltsi : GCCBuiltin<"__insn_v2cmpltsi">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2cmpltu : GCCBuiltin<"__insn_v2cmpltu">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2cmpltui : GCCBuiltin<"__insn_v2cmpltui">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2cmpne : GCCBuiltin<"__insn_v2cmpne">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2dotp : GCCBuiltin<"__insn_v2dotp">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2dotpa : GCCBuiltin<"__insn_v2dotpa">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2int_h : GCCBuiltin<"__insn_v2int_h">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2int_l : GCCBuiltin<"__insn_v2int_l">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2maxs : GCCBuiltin<"__insn_v2maxs">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2maxsi : GCCBuiltin<"__insn_v2maxsi">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2mins : GCCBuiltin<"__insn_v2mins">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2minsi : GCCBuiltin<"__insn_v2minsi">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2mnz : GCCBuiltin<"__insn_v2mnz">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2mulfsc : GCCBuiltin<"__insn_v2mulfsc">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2muls : GCCBuiltin<"__insn_v2muls">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2mults : GCCBuiltin<"__insn_v2mults">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2mz : GCCBuiltin<"__insn_v2mz">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2packh : GCCBuiltin<"__insn_v2packh">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2packl : GCCBuiltin<"__insn_v2packl">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2packuc : GCCBuiltin<"__insn_v2packuc">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2sadas : GCCBuiltin<"__insn_v2sadas">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2sadau : GCCBuiltin<"__insn_v2sadau">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2sads : GCCBuiltin<"__insn_v2sads">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2sadu : GCCBuiltin<"__insn_v2sadu">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2shl : GCCBuiltin<"__insn_v2shl">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2shli : GCCBuiltin<"__insn_v2shli">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2shlsc : GCCBuiltin<"__insn_v2shlsc">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2shrs : GCCBuiltin<"__insn_v2shrs">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2shrsi : GCCBuiltin<"__insn_v2shrsi">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2shru : GCCBuiltin<"__insn_v2shru">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2shrui : GCCBuiltin<"__insn_v2shrui">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2sub : GCCBuiltin<"__insn_v2sub">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v2subsc : GCCBuiltin<"__insn_v2subsc">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

// v4XXX
def int_tilegx_v4add : GCCBuiltin<"__insn_v4add">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], [Commutative]>;

def int_tilegx_v4addsc : GCCBuiltin<"__insn_v4addsc">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v4int_h : GCCBuiltin<"__insn_v4int_h">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v4int_l : GCCBuiltin<"__insn_v4int_l">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v4packsc : GCCBuiltin<"__insn_v4packsc">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v4shl : GCCBuiltin<"__insn_v4shl">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v4shlsc : GCCBuiltin<"__insn_v4shlsc">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v4shrs : GCCBuiltin<"__insn_v4shrs">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v4shru : GCCBuiltin<"__insn_v4shru">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v4sub : GCCBuiltin<"__insn_v4sub">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

def int_tilegx_v4subsc : GCCBuiltin<"__insn_v4subsc">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty], []>;

// Network
def int_tilegx_idn0r : GCCBuiltin<"__tile_idn0_receive">,
  Intrinsic<[llvm_i64_ty], [], []>;

def int_tilegx_idn1r : GCCBuiltin<"__tile_idn1_receive">,
  Intrinsic<[llvm_i64_ty], [], []>;

def int_tilegx_udn0r : GCCBuiltin<"__tile_udn0_receive">,
  Intrinsic<[llvm_i64_ty], [], []>;

def int_tilegx_udn1r : GCCBuiltin<"__tile_udn1_receive">,
  Intrinsic<[llvm_i64_ty], [], []>;

def int_tilegx_udn2r : GCCBuiltin<"__tile_udn2_receive">,
  Intrinsic<[llvm_i64_ty], [], []>;

def int_tilegx_udn3r : GCCBuiltin<"__tile_udn3_receive">,
  Intrinsic<[llvm_i64_ty], [], []>;

def int_tilegx_netbarrier : GCCBuiltin<"__tile_network_barrier">,
  Intrinsic<[], [], []>;

def int_tilegx_usend : GCCBuiltin<"__tile_udn_send">,
  Intrinsic<[], [llvm_i64_ty], []>;

def int_tilegx_isend : GCCBuiltin<"__tile_idn_send">,
  Intrinsic<[], [llvm_i64_ty], []>;

// Others
def int_tilegx_mfspr : GCCBuiltin<"__insn_mfspr">,
  Intrinsic<[llvm_i64_ty], [llvm_i64_ty], []>;

def int_tilegx_mtspr : GCCBuiltin<"__insn_mtspr">,
  Intrinsic<[], [llvm_i64_ty, llvm_i64_ty], []>;
} // end TargetPrefix
