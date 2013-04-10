; RUN: llc -march=tilegx < %s | FileCheck %s

define float @test0(float %a, float %b) {
; CHECK: test0:

entry:
	%0 = fmul float %a, %b
	ret float %0

; CHECK: __mulsf3
}

define float @test1(float %a) nounwind {
; CHECK: test1:

entry:
  %ret = fmul float %a, 2.0
  ret float %ret

; CHECK: __addsf3
}

define double @test2(double %a, double %b) {
; CHECK: test2:

entry:
	%0 = fmul double %a, %b
	ret double %0

; CHECK: __muldf3
}

define double @test3(double %a) nounwind {
; CHECK: test3:

entry:
  %ret = fmul double %a, 2.0
  ret double %ret

; CHECK: __adddf3
}
