; RUN: llc -march=tilegx < %s | FileCheck %s

define i32 @f1(i32 %a.s) {
; CHECK: f1:

entry:
    %tmp = icmp eq i32 %a.s, 4
    %tmp1.s = select i1 %tmp, i32 2, i32 3
    ret i32 %tmp1.s

; CHECK: cmovnez
}

define i64 @f2(i64 %a.s) {
; CHECK: f2:

entry:
    %tmp = icmp eq i64 %a.s, 4
    %tmp1.s = select i1 %tmp, i64 2, i64 3
    ret i64 %tmp1.s

; CHECK: cmovnez
}
