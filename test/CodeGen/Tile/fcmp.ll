; RUN: llc -march=tilegx < %s | FileCheck %s

define i32 @f0(float %a) {
; CHECK: f0:

entry:
        %tmp = fcmp oeq float %a, 1.000000e+00
        %tmp2 = zext i1 %tmp to i32
        ret i32 %tmp2

; CHECK: __eqsf2
}

define i32 @f1(float %a) {
; CHECK: f1:

entry:
        %tmp = fcmp olt float %a, 1.000000e+00
        %tmp1 = zext i1 %tmp to i32
        ret i32 %tmp1

; CHECK: __ltsf2
}

define i32 @f2(float %a) {
; CHECK: f2:

entry:
        %tmp = fcmp ole float %a, 1.000000e+00
        %tmp5 = zext i1 %tmp to i32
        ret i32 %tmp5
; CHECK: __lesf2
}

define i32 @f3(float %a) {
; CHECK: f3:

entry:
        %tmp = fcmp ogt float %a, 1.000000e+00
        %tmp3 = zext i1 %tmp to i32
        ret i32 %tmp3

; CHECK: __gtsf2
}

define i32 @f4(float %a) {
; CHECK: f4:

entry:
        %tmp = fcmp oge float %a, 1.000000e+00
        %tmp4 = zext i1 %tmp to i32
        ret i32 %tmp4

; CHECK: __gesf2
}

define i32 @f5(double %a) {
; CHECK: f5:

entry:
        %tmp = fcmp oeq double %a, 1.000000e+00
        %tmp2 = zext i1 %tmp to i32
        ret i32 %tmp2

; CHECK: __eqdf2
}

define i32 @f6(double %a) {
; CHECK: f6:

entry:
        %tmp = fcmp olt double %a, 1.000000e+00
        %tmp1 = zext i1 %tmp to i32
        ret i32 %tmp1

; CHECK: __ltdf2
}

define i32 @f7(double %a) {
; CHECK: f7:

entry:
        %tmp = fcmp ole double %a, 1.000000e+00
        %tmp5 = zext i1 %tmp to i32
        ret i32 %tmp5

; CHECK: __ledf2
}

define i32 @f8(double %a) {
; CHECK: f8:

entry:
        %tmp = fcmp ogt double %a, 1.000000e+00
        %tmp3 = zext i1 %tmp to i32
        ret i32 %tmp3

; CHECK: __gtdf2
}

define i32 @f9(double %a) {
; CHECK: f9:

entry:
        %tmp = fcmp oge double %a, 1.000000e+00
        %tmp4 = zext i1 %tmp to i32
        ret i32 %tmp4

; CHECK: __gedf2
}
