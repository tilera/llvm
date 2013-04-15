; RUN: llc -soft-float -march=tilegx < %s | FileCheck %s

define float @test0(float %a, float %b) {
entry:
	%0 = fdiv float %a, %b
	ret float %0
; CHECK: test0
; CHECK: __divsf3
}

define float @test1(float %a) nounwind {
  %ret = fdiv float %a, 2.0
  ret float %ret
; CHECK: test0
; CHECK: moveli [[REG0:r[0-9]+]], 16384
; CHECK: shl16insli {{r[0-9]+}}, [[REG0]], 0
; CHECK: __divsf3
}

define double @test2(double %a, double %b) {
entry:
	%0 = fdiv double %a, %b
	ret double %0
; CHECK: test2
; CHECK: __divdf3
}

define double @test3(double %a) nounwind {
  %ret = fdiv double %a, 2.0
  ret double %ret
; CHECK: test3
; CHECK: moveli [[REG0:r[0-9]+]], 16384
; CHECK: shl16insli {{r[0-9]+}}, [[REG0]], 0
; CHECK: shl16insli
; CHECK: shl16insli
; CHECK: __divdf3
}
