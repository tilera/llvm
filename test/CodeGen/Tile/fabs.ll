; RUN: llc -march=tilegx < %s | FileCheck %s

define float @foo0(float %a) nounwind readnone {
; CHECK: foo0:

entry:

  %call = tail call float @fabsf(float %a) nounwind readnone
  ret float %call

; CHECK: bfins r0, zero, 31, 31
}

declare float @fabsf(float) nounwind readnone

define double @foo1(double %a) nounwind readnone {
; CHECK: foo1:

entry:

  %call = tail call double @fabs(double %a) nounwind readnone
  ret double %call

; CHECK: bfins r0, zero, 63, 63
}

declare double @fabs(double) nounwind readnone
