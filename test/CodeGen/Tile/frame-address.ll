; RUN: llc -march=tilegx < %s | FileCheck %s

declare i8* @llvm.frameaddress(i32) nounwind readnone

define i8* @f() nounwind {
; CHECK: f:

entry:
  %0 = call i8* @llvm.frameaddress(i32 0)
  ret i8* %0

; CHECK: add r52, sp, zero
; CHECK: add r0, zero, r52
}
