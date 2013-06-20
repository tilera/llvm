; RUN: llc -O0 -march=tilegx < %s | FileCheck %s -check-prefix=HARD
; RUN: llc -soft-float -march=tilegx < %s | FileCheck %s -check-prefix=SOFT

define float @test0(float %a, float %b) {
; SOFT: test0:
; HARD: test0:

entry:
	%0 = fmul float %a, %b
	ret float %0

; SOFT: __mulsf3
; HARD: fsingle_mul1 [[TMP1:r[0-9]+]], [[SRCA:r[0-9]+]], [[SRCB:r[0-9]+]]
; HARD: fsingle_mul2 [[TMP2:r[0-9]+]], [[TMP1]], [[SRCB]]
; HARD: fsingle_pack1 [[FLAG:r[0-9]+]], [[TMP2]]
; HARD: fsingle_pack2 {{r[0-9]+}}, [[TMP2]], [[FLAG]]
}

define float @test1(float %a) nounwind {
; SOFT: test1:
; HARD: test1:

entry:
  %ret = fmul float %a, 2.0
  ret float %ret

; SOFT: __addsf3
; HARD: fsingle_add1 [[TMP1:r[0-9]+]], [[SRCA:r[0-9]+]], [[SRCB:r[0-9]+]]
; HARD: fsingle_addsub2 [[TMP1]], [[SRCA]], [[SRCB]]
; HARD: fsingle_pack1 [[FLAG:r[0-9]+]], [[TMP1]]
; HARD: fsingle_pack2 {{r[0-9]+}}, [[TMP1]], [[FLAG]]
}

define double @test2(double %a, double %b) {
; SOFT: test2:
; HARD: test2:

entry:
	%0 = fmul double %a, %b
	ret double %0

; SOFT: __muldf3
; HARD: fdouble_unpack_max [[B_UNPACKED:r[0-9]+]], [[SRCB:r[0-9]+]], zero
; HARD: fdouble_unpack_max [[A_UNPACKED:r[0-9]+]], [[SRCA:r[0-9]+]], zero
; HARD: mul_hu_lu [[MID:r[0-9]+]], [[A_UNPACKED]], [[B_UNPACKED]]
; HARD: mula_hu_lu [[MID:r[0-9]+]], [[B_UNPACKED]], [[A_UNPACKED]]
; HARD: mul_hu_hu [[HIGH1:r[0-9]+]], [[A_UNPACKED]], [[B_UNPACKED]]
; HARD: shrui [[MID_R32:r[0-9]+]], [[MID]], 32
; HARD: add [[TMP1:r[0-9]+]], [[HIGH1]], [[MID_R32]]
; HARD: mul_lu_lu [[LOW1:r[0-9]+]], [[A_UNPACKED]], [[B_UNPACKED]]
; HARD: shli [[MID_L32:r[0-9]+]], [[MID]], 32
; HARD: add [[LOW:r[0-9]+]], [[LOW1]], [[MID_L32]]
; HARD: cmpltu [[LOW_C:r[0-9]+]], [[LOW]], [[MID_L32]]
; HARD: add [[HIGH:r[0-9]+]], [[TMP1]], [[LOW_C]]
; HARD: fdouble_mul_flags [[FLAG:r[0-9]+]], [[SRCA]], [[SRCB]]
; HARD: fdouble_pack1 [[RESULT:r[0-9]+]], [[HIGH]], [[FLAG]]
; HARD: fdouble_pack2 [[RESULT]], [[HIGH]], [[LOW]]
}

define double @test3(double %a) nounwind {
; SOFT: test3:
; HARD: test3:

entry:
  %ret = fmul double %a, 2.0
  ret double %ret

; SOFT: __adddf3
; HARD: fdouble_unpack_max [[MAX:r[0-9]+]], [[SRCA:r[0-9]+]], [[SRCB:r[0-9]+]]
; HARD: fdouble_add_flags [[FLAG:r[0-9]+]], [[SRCA:r[0-9]+]], [[SRCB:r[0-9]+]]
; HARD: fdouble_unpack_min [[MIN:r[0-9]+]], [[SRCA:r[0-9]+]], [[SRCB:r[0-9]+]]
; HARD: fdouble_addsub [[MAX]], [[MIN]], [[FLAG]]
; HARD: fdouble_pack1 [[RESULT:r[0-9]+]], [[MAX]], [[FLAG]]
; HARD: fdouble_pack2 [[RESULT]], [[MAX]], zero
}
