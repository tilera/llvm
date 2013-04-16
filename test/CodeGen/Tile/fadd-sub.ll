; RUN: llc -O0 -march=tilegx < %s | FileCheck %s -check-prefix=HARD
; RUN: llc -soft-float -march=tilegx < %s | FileCheck %s -check-prefix=SOFT

define float @fadd(float %a, float %b) {
; SOFT: fadd:
; HARD: fadd:

entry:
	%0 = fadd float %a, %b
	ret float %0

; SOFT: __addsf3
; HARD: fsingle_add1 [[TMP1:r[0-9]+]], [[SRCA:r[0-9]+]], [[SRCB:r[0-9]+]]
; HARD: fsingle_addsub2 [[TMP1]], [[SRCA]], [[SRCB]]
; HARD: fsingle_pack1 [[FLAG:r[0-9]+]], [[TMP1]]
; HARD: fsingle_pack2 {{r[0-9]+}}, [[TMP1]], [[FLAG]]
}

define float @fsub(float %a, float %b) {
; SOFT: fsub:
; HARD: fsub:

entry:
	%0 = fsub float %a, %b
	ret float %0

; SOFT: __subsf3
; HARD: fsingle_sub1 [[TMP1:r[0-9]+]], [[SRCA:r[0-9]+]], [[SRCB:r[0-9]+]]
; HARD: fsingle_addsub2 [[TMP1]], [[SRCA]], [[SRCB]]
; HARD: fsingle_pack1 [[FLAG:r[0-9]+]], [[TMP1]]
; HARD: fsingle_pack2 {{r[0-9]+}}, [[TMP1]], [[FLAG]]
}

define double @dadd(double %a, double %b) {
; SOFT: dadd:
; HARD: dadd:

entry:
	%0 = fadd double %a, %b
	ret double %0

; SOFT: __adddf3
; HARD: fdouble_unpack_max [[MAX:r[0-9]+]], [[SRCA:r[0-9]+]], [[SRCB:r[0-9]+]]
; HARD: fdouble_add_flags [[FLAG:r[0-9]+]], [[SRCA:r[0-9]+]], [[SRCB:r[0-9]+]]
; HARD: fdouble_unpack_min [[MIN:r[0-9]+]], [[SRCA:r[0-9]+]], [[SRCB:r[0-9]+]]
; HARD: fdouble_addsub [[MAX]], [[MIN]], [[FLAG]]
; HARD: fdouble_pack1 [[RESULT:r[0-9]+]], [[MAX]], [[FLAG]]
; HARD: fdouble_pack2 [[RESULT]], [[MAX]], zero
}

define double @dsub(double %a, double %b) {
; SOFT: dsub:
; HARD: dsub:

entry:
	%0 = fsub double %a, %b
	ret double %0

; SOFT: __subdf3
; HARD: fdouble_unpack_max [[MAX:r[0-9]+]], [[SRCA:r[0-9]+]], [[SRCB:r[0-9]+]]
; HARD: fdouble_sub_flags [[FLAG:r[0-9]+]], [[SRCA:r[0-9]+]], [[SRCB:r[0-9]+]]
; HARD: fdouble_unpack_min [[MIN:r[0-9]+]], [[SRCA:r[0-9]+]], [[SRCB:r[0-9]+]]
; HARD: fdouble_addsub [[MAX]], [[MIN]], [[FLAG]]
; HARD: fdouble_pack1 [[RESULT:r[0-9]+]], [[MAX]], [[FLAG]]
; HARD: fdouble_pack2 [[RESULT]], [[MAX]], zero
}
