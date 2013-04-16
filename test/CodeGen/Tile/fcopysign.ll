; RUN: llc -march=tilegx < %s | FileCheck %s

define double @func0(double %d0, double %d1) nounwind readnone {
; CHECK: func0:

entry:

  %call = tail call double @copysign(double %d0, double %d1) nounwind readnone
  ret double %call

; CHECK: bfextu [[REG0:r[0-9]+]], {{r[0-9]+}}, 63, 63
; CHECK: bfins {{r[0-9]+}}, [[REG0]], 63, 63
}

declare double @copysign(double, double) nounwind readnone

define float @func1(float %f0, float %f1) nounwind readnone {
; CHECK: func1:

entry:

  %call = tail call float @copysignf(float %f0, float %f1) nounwind readnone
  ret float %call

; CHECK: bfextu [[REG0:r[0-9]+]], {{r[0-9]+}}, 31, 31
; CHECK: bfins {{r[0-9]+}}, [[REG0]], 31, 31
}

declare float @copysignf(float, float) nounwind readnone
