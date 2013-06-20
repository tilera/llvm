; RUN: llc -march=tilegx < %s | FileCheck %s

declare i64 @llvm.ctlz.i64(i64, i1) nounwind readnone
declare i32 @llvm.ctlz.i32(i32, i1) nounwind readnone

define i64 @test64(i64 %x) {
; CHECK: test64:

entry:
  %count = tail call i64 @llvm.ctlz.i64(i64 %x, i1 false)
  ret i64 %count

; CHECK: clz r{{[0-9]+}}, r{{[0-9]+}}
}

define i32 @test32(i32 %x) {
; CHECK: test32:

entry:
  %count = tail call i32 @llvm.ctlz.i32(i32 %x, i1 false)
  ret i32 %count

; CHECK: shli [[REG:r[0-9]+]], [[REG]], 32
; CHECK: clz r{{[0-9]+}}, [[REG]]
}
