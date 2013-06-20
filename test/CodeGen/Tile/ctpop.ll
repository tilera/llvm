; RUN: llc -march=tilegx < %s | FileCheck %s

declare i64 @llvm.ctpop.i64(i64) nounwind readnone
declare i32 @llvm.ctpop.i32(i32) nounwind readnone

define i64 @test64(i64 %x) {
; CHECK: test64:

entry:
  %count = tail call i64 @llvm.ctpop.i64(i64 %x)
  ret i64 %count

; CHECK: pcnt r{{[0-9]+}}, r{{[0-9]+}}
}

define i32 @test32(i32 %x) {
; CHECK: test32:

entry:
  %count = tail call i32 @llvm.ctpop.i32(i32 %x)
  ret i32 %count

; CHECK: v4int_l [[REG:r[0-9]+]], zero, r{{[0-9]+}}
; CHECK: pcnt r{{[0-9]+}}, [[REG]]
}
