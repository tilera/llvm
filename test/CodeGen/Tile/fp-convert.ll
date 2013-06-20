; RUN: llc -march=tilegx < %s | FileCheck %s -check-prefix=HARD
; RUN: llc -soft-float -march=tilegx < %s | FileCheck %s -check-prefix=SOFT

define float @i2f(i32 %x) {
; SOFT: i2f:
; HARD: i2f:

entry:
  %a = sitofp i32 %x to float
  ret float %a

; SOFT: __floatsisf
; HARD: sub [[NEGA:r[0-9]+]], zero, [[SRCA:r[0-9]+]]
; HARD: cmpltsi [[SIGN:r[0-9]+]], [[SRCA]], 0
; HARD: cmovnez [[SRCA]], [[SIGN]], [[NEGA]]
; HARD: moveli [[EXP:r[0-9]+]], 158
; HARD: bfins [[EXP]], [[SIGN]], 10, 10
; HARD: bfins [[EXP]], [[SRCA]], 32, 63
; HARD: fsingle_pack1 [[FLAG:r[0-9]+]], [[EXP]]
; HARD: fsingle_pack2 {{r[0-9]+}}, [[EXP]], [[FLAG]]
}

define double @i2d(i32 %x) {
; SOFT: i2d:
; HARD: i2d:

entry:
  %a = sitofp i32 %x to double
  ret double %a

; SOFT: __floatsidf
; HARD: sub [[NEGA:r[0-9]+]], zero, [[SRCA:r[0-9]+]]
; HARD: cmpltsi [[SIGN:r[0-9]+]], [[SRCA]], 0
; HARD: cmovnez [[SRCA]], [[SIGN]], [[NEGA]]
; HARD: moveli [[ENP:r[0-9]+]], 539
; HARD: shli [[EXP:r[0-9]+]], [[ENP]], 8
; HARD: bfins [[EXP]], [[SIGN]], 20, 20
; HARD: shli [[TMP1:r[0-9]+]], [[SRCA]], 4
; HARD: fdouble_pack1 [[FLAG:r[0-9]+]], [[TMP1]], [[EXP]]
; HARD: fdouble_pack2 [[FLAG]], [[TMP1]], zero
}

define float @u2f(i32 %x) {
; SOFT: u2f:
; HARD: u2f:

entry:
  %a = uitofp i32 %x to float
  ret float %a

; SOFT: __floatunsisf
; HARD: moveli [[EXP:r[0-9]+]], 158
; HARD: bfins [[EXP]], [[SRCA:r[0-9]+]], 32, 63
; HARD: fsingle_pack1 [[FLAG:r[0-9]+]], [[EXP]]
; HARD: fsingle_pack2 {{r[0-9]+}}, [[EXP]], [[FLAG]]
}

define double @u2d(i32 %x) {
; SOFT: u2d:
; HARD: u2d:

entry:
  %a = uitofp i32 %x to double
  ret double %a

; SOFT: __floatunsidf
; HARD: bfins [[TMP1:r[0-9]+]], [[SRCA:r[0-9]+]], 4, 35
; HARD: moveli [[ENP:r[0-9]+]], 539
; HARD: shli [[EXP:r[0-9]+]], [[ENP]], 8
; HARD: fdouble_pack1 [[TMP2:r[0-9]+]], [[TMP1]], [[EXP]]
; HARD: fdouble_pack2 [[TMP2]], [[TMP1]], zero
}
