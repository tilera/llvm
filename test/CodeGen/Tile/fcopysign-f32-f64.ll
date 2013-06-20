; RUN: llc  -march=tilegx < %s | FileCheck %s

declare double @copysign(double, double) nounwind readnone

declare float @copysignf(float, float) nounwind readnone

define float @func2(float %d, double %f) nounwind readnone {
; CHECK: func2:

entry:

  %add = fadd float %d, 1.000000e+00
  %conv = fptrunc double %f to float
  %call = tail call float @copysignf(float %add, float %conv) nounwind readnone
  ret float %call

; CHECK: fsingle_pack1 {{r[0-9]+}}, {{r[0-9]+}}
; CHECK: fsingle_pack2 [[REG0:r[0-9]+]], {{r[0-9]+}}, {{r[0-9]+}}
; CHECK: bfextu [[REG1:r[0-9]+]], {{r[0-9]+}}, 63, 63
; CHECK: bfins [[REG0]], [[REG1]], 31, 31
}

define double @func3(double %d, float %f) nounwind readnone {
; CHECK: func3:

entry:

  %add = fadd double %d, 1.000000e+00
  %conv = fpext float %f to double
  %call = tail call double @copysign(double %add, double %conv) nounwind readnone
  ret double %call

; CHECK: fdouble_pack1 {{r[0-9]+}}, {{r[0-9]+}}
; CHECK: fdouble_pack2 [[REG0:r[0-9]+]], {{r[0-9]+}}, zero
; CHECK: bfextu [[REG1:r[0-9]+]], {{r[0-9]+}}, 31, 31
; CHECK: bfins [[REG0]], [[REG1]], 63, 63
}
