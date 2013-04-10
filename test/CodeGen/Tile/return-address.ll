; RUN: llc -march=tilegx < %s | FileCheck %s

define i8* @f1() nounwind {
; CHECK: f1:

entry:
  %0 = call i8* @llvm.returnaddress(i32 0)
  ret i8* %0

; CHECK: add r0, zero, lr
}

define i8* @f2() nounwind {
; CHECK: f2:

entry:
  call void @g()
  %0 = call i8* @llvm.returnaddress(i32 0)
  ret i8* %0

; CHECK: add [[REG0:r[0-9]+]], zero, lr
; CHECK: jal
; CHECK: add r0, zero, [[REG0]]
}

declare i8* @llvm.returnaddress(i32) nounwind readnone
declare void @g()
