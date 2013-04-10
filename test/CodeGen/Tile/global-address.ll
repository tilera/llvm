; RUN: llc -march=tilegx -relocation-model=pic < %s | FileCheck %s -check-prefix=PIC
; RUN: llc -march=tilegx -relocation-model=static < %s | FileCheck %s -check-prefix=STATIC

@s1 = internal global i32 8, align 4
@g1 = external global i32

define void @foo() nounwind {
; PIC: foo:
; STATIC: foo:

entry:
  %0 = load i32* @s1, align 4
  tail call void @foo1(i32 %0) nounwind
  %1 = load i32* @g1, align 4
  store i32 %1, i32* @s1, align 4
  %add = add i32 %1, 2
  store i32 %add, i32* @g1, align 4
  ret void

; setup gp.
; PIC:      .L0$pb = . + 8
; PIC-NEXT: lnk [[TP:r50]]
; PIC:      moveli [[GP:r51]], hw1_last([[GOT:_GLOBAL_OFFSET_TABLE_]] - .L0$pb)
; PIC:      shl16insli [[GP]], [[GP]], hw0([[GOT]] - .L0$pb)
; PIC:      add [[GP]], [[GP]], [[TP]]
; for s1, it is a internal variable, so use pc-relative access.
; PIC:      moveli [[REG0:r[0-9]+]], hw1_last(s1 - .L0$pb)
; PIC:      shl16insli [[REG1:r[0-9]+]], [[REG0]], hw0(s1 - .L0$pb)
; PIC:      add {{r[0-9]+}}, [[TP]], [[REG1]]
; for g1, it is a external variable, so use GOT based access.
; PIC:      moveli [[REG0:r[0-9]+]], hw1_last_got(g1)
; PIC:      shl16insli [[REG1:r[0-9]+]], [[REG0]], hw0_got(g1)
; PIC:      add {{r[0-9]+}}, [[GP]], [[REG1]]

; STATIC: moveli [[REG0:r[0-9]+]], hw2_last(s1)
; STATIC: shl16insli [[REG1:r[0-9]+]], [[REG0]], hw1(s1)
; STATIC: shl16insli {{r[0-9]+}}, [[REG1]], hw0(s1)
; STATIC: moveli [[REG2:r[0-9]+]], hw2_last(g1)
; STATIC: shl16insli [[REG3:r[0-9]+]], [[REG2]], hw1(g1)
; STATIC: shl16insli [[REG4:r[0-9]+]], [[REG3]], hw0(g1)
}

declare void @foo1(i32)
