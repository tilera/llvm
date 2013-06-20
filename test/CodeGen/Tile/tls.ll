; RUN: llc -march=tilegx -relocation-model=pic < %s | FileCheck %s -check-prefix=PIC
; RUN: llc -march=tilegx -relocation-model=static < %s | FileCheck %s -check-prefix=STATIC

@t1 = internal thread_local global i32 0, align 4

define i32 @f1() nounwind {
; PIC: f1:
; STATIC: f1:

entry:
  %tmp = load i32* @t1, align 4
  ret i32 %tmp

; setup gp.
; PIC:      .L[[NUM:[0-9]+]]$pb = . + 8
; PIC-NEXT: lnk [[TP:r50]]
; PIC:      moveli [[GP:r51]], hw1_last([[GOT:_GLOBAL_OFFSET_TABLE_]] - .L[[NUM]]$pb)
; PIC:      shl16insli [[GP]], [[GP]], hw0([[GOT]] - .L[[NUM]]$pb)
; PIC:      add [[GP]], [[GP]], [[TP]]
; fetch GD descriptor from GOT.
; PIC:      moveli [[REG0:r[0-9]+]], hw1_last_tls_gd(t1)
; PIC:      shl16insli [[REG1:r[0-9]+]], [[REG0]], hw0_tls_gd(t1)
; the result must be placed in r0 as the first arg to tls_gd_call.
; PIC:      addi r0, [[GP]], tls_add(t1)
; PIC:      jal tls_gd_call(t1)
; PIC:      addi {{r[0-9]+}}, r0, tls_gd_add(t1)

; STATIC:   moveli [[REG0:r[0-9]+]], hw1_last_tls_le(t1)
; STATIC:   shl16insli [[REG1:r[0-9]+]], [[REG0]], hw0_tls_le(t1)
; STATIC:   add {{r[0-9]+}}, [[REG1]], tp
}


@t2 = external thread_local global i32

define i32 @f2() nounwind {
; PIC: f2:
; STATIC: f2:

entry:
  %tmp = load i32* @t2, align 4
  ret i32 %tmp

; setup gp.
; PIC:      .L[[NUM:[0-9]+]]$pb = . + 8
; PIC-NEXT: lnk [[TP:r50]]
; PIC:      moveli [[GP:r51]], hw1_last([[GOT:_GLOBAL_OFFSET_TABLE_]] - .L[[NUM]]$pb)
; PIC:      shl16insli [[GP]], [[GP]], hw0([[GOT]] - .L[[NUM]]$pb)
; PIC:      add [[GP]], [[GP]], [[TP]]
; fetch GD descriptor from GOT.
; PIC:      moveli [[REG0:r[0-9]+]], hw1_last_tls_gd(t2)
; PIC:      shl16insli [[REG1:r[0-9]+]], [[REG0]], hw0_tls_gd(t2)
; the result must be placed in r0 as the first arg to tls_gd_call.
; PIC:      addi r0, [[GP]], tls_add(t2)
; PIC:      jal tls_gd_call(t2)
; PIC:      addi {{r[0-9]+}}, r0, tls_gd_add(t2)

; STATIC:      .L[[NUM:[0-9]+]]$pb = . + 8
; STATIC-NEXT: lnk [[TP:r50]]
; STATIC:      moveli [[GP:r51]], hw1_last([[GOT:_GLOBAL_OFFSET_TABLE_]] - .L[[NUM]]$pb)
; STATIC:      shl16insli [[GP]], [[GP]], hw0([[GOT]] - .L[[NUM]]$pb)
; STATIC:      add [[GP]], [[GP]], [[TP]]
; fetch IE descriptor from GOT.
; STATIC:      moveli [[REG0:r[0-9]+]], hw1_last_tls_ie(t2)
; STATIC:      shl16insli [[REG1:r[0-9]+]], [[REG0]], hw0_tls_ie(t2)
; STATIC:      addi {{r[0-9]+}}, [[GP]], tls_add(t2)
; STATIC:      ld_tls {{r[0-9]+}}, {{r[0-9]+}}, tls_ie_load(t2)
; STATIC:      add {{r[0-9]+}}, {{r[0-9]+}}, tp
}
