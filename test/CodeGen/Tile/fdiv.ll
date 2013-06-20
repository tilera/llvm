; RUN: llc -march=tilegx < %s | FileCheck %s

define float @test0(float %a, float %b) {
; CHECK: test0

entry:
	%0 = fdiv float %a, %b
	ret float %0

; CHECK: __divsf3
}

define float @test1(float %a) nounwind {
; CHECK: test1

entry:
  %ret = fdiv float %a, 2.0
  ret float %ret

; CHECK: moveli [[REG0:r[0-9]+]]
; CHECK: shl16insli {{r[0-9]+}}, [[REG0]]
; CHECK: __divsf3
}

define double @test2(double %a, double %b) {
; CHECK: test2

entry:
	%0 = fdiv double %a, %b
	ret double %0

; CHECK: __divdf3
}

define double @test3(double %a) nounwind {
; CHECK: test3

entry:
  %ret = fdiv double %a, 2.0
  ret double %ret

; CHECK: moveli [[REG0:r[0-9]+]]
; CHECK: shl16insli {{r[0-9]+}}, [[REG0]]
; CHECK: shl16insli
; CHECK: __divdf3
}
