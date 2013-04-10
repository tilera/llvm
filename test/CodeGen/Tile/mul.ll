; RUN: llc -march=tilegx < %s | FileCheck %s

define i32 @f1(i32 %u) {
; CHECK: f1:

entry:
    %tmp = mul i32 %u, %u
    ret i32 %tmp

; CHECK: mulx
}

define i64 @f2(i64 %u, i64 %v) {
; CHECK: f2:

entry:
    %tmp = mul i64 %u, %v
    ret i64 %tmp

; CHECK: mul_hu_lu [[REG0:r[0-9]+]], [[REG1:r[0-9]+]], [[REG2:r[0-9]+]]
; CHECK: mula_hu_lu [[REG0]], [[REG2]], [[REG1]]
; CHECK: shli [[REG3:r[0-9]+]], [[REG0]], 32
; CHECK: mula_lu_lu [[REG3]], [[REG2]], [[REG1]]
}

define i32 @f3(i32 %u) {
; CHECK: f3:

entry:
	%tmp = mul i32 %u, 5
        ret i32 %tmp

; CHECK: movei r{{[0-9]+}}, 5
; CHECK: mulx
}

define i32 @f4(i32 %u) {
; CHECK: f4:

entry:
	%tmp = mul i32 %u, 4
        ret i32 %tmp

; CHECK: shlxi r{{[0-9]+}}, r{{[0-9]+}}, 2
}

define i32 @f5(i32 %u) {
; CHECK: f5:

entry:
	%tmp = mul i32 %u, -2147483648
        ret i32 %tmp

; CHECK: shlxi r{{[0-9]+}}, r{{[0-9]+}}, 31
}

define i64 @f6(i64 %u) {
; CHECK: f6:

entry:
	%tmp = mul i64 %u, 281474976710656
        ret i64 %tmp

; CHECK: shli r{{[0-9]+}}, r{{[0-9]+}}, 48
}
