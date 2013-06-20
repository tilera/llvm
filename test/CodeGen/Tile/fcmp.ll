; RUN: llc -march=tilegx < %s | FileCheck %s -check-prefix=HARD
; RUN: llc -soft-float -march=tilegx < %s | FileCheck %s -check-prefix=SOFT

define i32 @f0(float %a) {
; SOFT: f0:
; HARD: f0:

entry:
        %tmp = fcmp oeq float %a, 1.000000e+00
        %tmp2 = zext i1 %tmp to i32
        ret i32 %tmp2

; SOFT: __eqsf2
; HARD: fsingle_add1 [[REG0:r[0-9]+]], {{r[0-9]+}}, {{r[0-9]+}}
; HARD: bfextu {{r[0-9]+}}, [[REG0]], 30, 30
}

define i32 @f1(float %a) {
; SOFT: f1:
; HARD: f1:

entry:
        %tmp = fcmp olt float %a, 1.000000e+00
        %tmp1 = zext i1 %tmp to i32
        ret i32 %tmp1

; SOFT: __ltsf2
; HARD: fsingle_add1 [[REG0:r[0-9]+]], {{r[0-9]+}}, {{r[0-9]+}}
; HARD: bfextu {{r[0-9]+}}, [[REG0]], 26, 26
}

define i32 @f2(float %a) {
; SOFT: f2:
; HARD: f2:

entry:
        %tmp = fcmp ole float %a, 1.000000e+00
        %tmp5 = zext i1 %tmp to i32
        ret i32 %tmp5
; SOFT: __lesf2
; HARD: fsingle_add1 [[REG0:r[0-9]+]], {{r[0-9]+}}, {{r[0-9]+}}
; HARD: bfextu {{r[0-9]+}}, [[REG0]], 27, 27
}

define i32 @f3(float %a) {
; SOFT: f3:
; HARD: f3:

entry:
        %tmp = fcmp ogt float %a, 1.000000e+00
        %tmp3 = zext i1 %tmp to i32
        ret i32 %tmp3

; SOFT: __gtsf2
; HARD: fsingle_add1 [[REG0:r[0-9]+]], {{r[0-9]+}}, {{r[0-9]+}}
; HARD: bfextu {{r[0-9]+}}, [[REG0]], 28, 28
}

define i32 @f4(float %a) {
; SOFT: f4:
; HARD: f4:

entry:
        %tmp = fcmp oge float %a, 1.000000e+00
        %tmp4 = zext i1 %tmp to i32
        ret i32 %tmp4

; SOFT: __gesf2
; HARD: fsingle_add1 [[REG0:r[0-9]+]], {{r[0-9]+}}, {{r[0-9]+}}
; HARD: bfextu {{r[0-9]+}}, [[REG0]], 29, 29
}

define i32 @f5(double %a) {
; SOFT: f5:
; HARD: f5:

entry:
        %tmp = fcmp oeq double %a, 1.000000e+00
        %tmp2 = zext i1 %tmp to i32
        ret i32 %tmp2

; SOFT: __eqdf2
; HARD: fdouble_add_flags [[REG0:r[0-9]+]], {{r[0-9]+}}, {{r[0-9]+}}
; HARD: bfextu {{r[0-9]+}}, [[REG0]], 30, 30
}

define i32 @f6(double %a) {
; SOFT: f6:
; HARD: f6:

entry:
        %tmp = fcmp olt double %a, 1.000000e+00
        %tmp1 = zext i1 %tmp to i32
        ret i32 %tmp1

; SOFT: __ltdf2
; HARD: fdouble_add_flags [[REG0:r[0-9]+]], {{r[0-9]+}}, {{r[0-9]+}}
; HARD: bfextu {{r[0-9]+}}, [[REG0]], 26, 26
}

define i32 @f7(double %a) {
; SOFT: f7:
; HARD: f7:

entry:
        %tmp = fcmp ole double %a, 1.000000e+00
        %tmp5 = zext i1 %tmp to i32
        ret i32 %tmp5

; SOFT: __ledf2
; HARD: fdouble_add_flags [[REG0:r[0-9]+]], {{r[0-9]+}}, {{r[0-9]+}}
; HARD: bfextu {{r[0-9]+}}, [[REG0]], 27, 27
}

define i32 @f8(double %a) {
; SOFT: f8:
; HARD: f8:

entry:
        %tmp = fcmp ogt double %a, 1.000000e+00
        %tmp3 = zext i1 %tmp to i32
        ret i32 %tmp3

; SOFT: __gtdf2
; HARD: fdouble_add_flags [[REG0:r[0-9]+]], {{r[0-9]+}}, {{r[0-9]+}}
; HARD: bfextu {{r[0-9]+}}, [[REG0]], 28, 28
}

define i32 @f9(double %a) {
; SOFT: f9:
; HARD: f9:

entry:
        %tmp = fcmp oge double %a, 1.000000e+00
        %tmp4 = zext i1 %tmp to i32
        ret i32 %tmp4

; SOFT: __gedf2
; HARD: fdouble_add_flags [[REG0:r[0-9]+]], {{r[0-9]+}}, {{r[0-9]+}}
; HARD: bfextu {{r[0-9]+}}, [[REG0]], 29, 29
}

define i32 @f10(float %a) {
; SOFT: f10:
; HARD: f10:

entry:
        %tmp = fcmp one float %a, 1.000000e+00
        %tmp4 = zext i1 %tmp to i32
        ret i32 %tmp4

; SOFT: __gtsf2
; SOFT: __ltsf2
; HARD: fsingle_add1 [[REG0:r[0-9]+]], {{r[0-9]+}}, {{r[0-9]+}}
; HARD: bfextu {{r[0-9]+}}, [[REG0]], 31, 31
}

define i32 @f11(double %a) {
; SOFT: f11:
; HARD: f11:

entry:
        %tmp = fcmp one double %a, 1.000000e+00
        %tmp4 = zext i1 %tmp to i32
        ret i32 %tmp4

; SOFT: __gtdf2
; SOFT: __ltdf2
; HARD: fdouble_add_flags [[REG0:r[0-9]+]], {{r[0-9]+}}, {{r[0-9]+}}
; HARD: bfextu {{r[0-9]+}}, [[REG0]], 31, 31
}
