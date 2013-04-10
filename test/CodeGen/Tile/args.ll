; RUN: llc -disable-dfa-sched -march=tilegx < %s | FileCheck %s

declare void @bar32(i32, i32, i32, i32, i32, i32, i32, i32, i32, i32)
declare void @bar64(i64, i64, i64, i64, i64, i64, i64, i64, i64, i64)

define void @foo() nounwind {
; CHECK: foo:

entry:
  call void @bar32(i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8, i32 9, i32 10)
  call void @bar64(i64 1, i64 2, i64 3, i64 4, i64 5, i64 6, i64 7, i64 8, i64 9, i64 10)
  ret void

; CHECK: movei r0, 1
; CHECK: movei r1, 2
; CHECK: movei r2, 3
; CHECK: movei r3, 4
; CHECK: movei r4, 5
; CHECK: movei r5, 6
; CHECK: movei r6, 7
; CHECK: movei r7, 8
; CHECK: movei r8, 9
; CHECK: movei r9, 10

; CHECK: movei r0, 1
; CHECK: movei r1, 2
; CHECK: movei r2, 3
; CHECK: movei r3, 4
; CHECK: movei r4, 5
; CHECK: movei r5, 6
; CHECK: movei r6, 7
; CHECK: movei r7, 8
; CHECK: movei r8, 9
; CHECK: movei r9, 10
}
