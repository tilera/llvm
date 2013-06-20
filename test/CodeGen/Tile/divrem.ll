; RUN: llc < %s -march=tilegx | FileCheck %s

define i32 @f1(i32 %a, i32 %b) {
; CHECK: f1:

entry:
  %tmp1 = sdiv i32 %a, %b
  ret i32 %tmp1

; CHECK: __divsi3
}

define i32 @f2(i32 %a, i32 %b) {
; CHECK: f2:

entry:
  %tmp1 = udiv i32 %a, %b
  ret i32 %tmp1

; CHECK: __udivsi3
}

define i32 @f3(i32 %a, i32 %b) {
; CHECK: f3:

entry:
  %tmp1 = srem i32 %a, %b
  ret i32 %tmp1

; CHECK: __modsi3
}

define i32 @f4(i32 %a, i32 %b) {
; CHECK: f4:

entry:
  %tmp1 = urem i32 %a, %b
  ret i32 %tmp1

; CHECK: __umodsi3
}

define i64 @f5(i64 %a, i64 %b) {
; CHECK: f5:

entry:
  %tmp1 = sdiv i64 %a, %b
  ret i64 %tmp1

; CHECK: __divdi3
}

define i64 @f6(i64 %a, i64 %b) {
; CHECK: f6:

entry:
  %tmp1 = udiv i64 %a, %b
  ret i64 %tmp1

; CHECK: __udivdi3
}

define i64 @f7(i64 %a, i64 %b) {
; CHECK: f7:

entry:
  %tmp1 = srem i64 %a, %b
  ret i64 %tmp1

; CHECK: __moddi3
}

define i64 @f8(i64 %a, i64 %b) {
; CHECK: f8:

entry:
  %tmp1 = urem i64 %a, %b
  ret i64 %tmp1

; CHECK: __umoddi3
}
