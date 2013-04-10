; RUN: llc -march=tilegx < %s | FileCheck %s

define i32 @foo0() nounwind readnone {
; CHECK: foo0:

entry:
  ret i32 305419896

; CHECK: moveli [[REG0:r[0-9]+]], 4660
; CHECK: shl16insli {{r[0-9]+}}, [[REG0]], 22136
}

define i32 @foo1() nounwind readnone {
; CHECK: foo1:

entry:
  ret i32 305397760

; CHECK: moveli [[REG0:r[0-9]+]], 4660
; CHECK: shl16insli {{r[0-9]+}}, [[REG0]], 0
}

define i32 @foo2() nounwind readnone {
; CHECK: foo2:

entry:
  ret i32 4660

; CHECK: moveli {{r[0-9]+}}, 4660
}

define i32 @foo3() nounwind readnone {
; CHECK: foo3:

entry:
  ret i32 32768

; CHECK: shl16insli {{r[0-9]+}}, zero, -32768
}

define i32 @foo4() nounwind readnone {
; CHECK: foo4:

entry:
  ret i32 -32768

; CHECK: moveli {{r[0-9]+}}, -32768
}

define i64 @foo5() nounwind readnone {
; CHECK: foo5:

entry:
  ret i64 3405695742;

; CHECK: shl16insli [[REG0:r[0-9]+]], zero, -13570
; CHECK: shl16insli {{r[0-9]+}}, [[REG0]], -13570
}

define i64 @foo6() nounwind readnone {
; CHECK: foo6:

entry:
  ret i64 223195676199678;

; CHECK: shl16insli [[REG0:r[0-9]+]], zero, -13570
; CHECK: shl16insli [[REG1:r[0-9]+]], [[REG0]], -13570
; CHECK: shl16insli {{r[0-9]+}}, [[REG1]], -13570
}
