; RUN: llc -march=tilegx < %s | FileCheck %s

define i8* @e(i32 %a) {
; CHECK: e:

entry:
        %tmp = alloca i8, i32 %a                ; <i8*> [#uses=1]
        ret i8* %tmp

; CHECK: add {{r[0-9]+}}, zero, sp
; CHECK: add sp, zero, {{r[0-9]+}}
}

define void @f(i32 %a) {
; CHECK: f:

entry:
        %tmp = alloca i8, i32 %a                ; <i8*> [#uses=1]
        call void @g( i8* %tmp, i32 %a, i32 1, i32 2, i32 3 )
        ret void

; for non-tail call, check whether the 16bytes tilegx
; reserved zone is backed up
; CHECK: addi {{r[0-9]+}}, sp, 8
; CHECK: add sp, zero, {{r[0-9]+}}
}

declare void @g(i8*, i32, i32, i32, i32)
