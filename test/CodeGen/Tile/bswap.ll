; RUN: llc -march=tilegx < %s | FileCheck %s

define i32 @bswap32(i32 %x) nounwind readnone {
; CHECK: bswap32:

entry:
  %0 = call i32 @llvm.bswap.i32(i32 %x)
  ret i32 %0

; CHECK: revbytes [[REG0:r[0-9]+]], r0
; CHECK: shrui r0, [[REG0]], 32
}

define i64 @bswap64(i64 %x) nounwind readnone {
; CHECK: bswap64:

entry:
  %0 = call i64 @llvm.bswap.i64(i64 %x)
  ret i64 %0

; CHECK: revbytes r0, r0
}

declare i32 @llvm.bswap.i32(i32) nounwind readnone
declare i64 @llvm.bswap.i64(i64) nounwind readnone
