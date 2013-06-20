; RUN: llc -march=tilegx -relocation-model=pic < %s | FileCheck %s -check-prefix=PIC
; RUN: llc -march=tilegx -relocation-model=static < %s | FileCheck %s -check-prefix=STATIC

; tilegx do not support local dynamic model
@external_gd = external thread_local global i32
@internal_gd = internal thread_local global i32 42

@external_ie = external thread_local(initialexec) global i32
@internal_ie = internal thread_local(initialexec) global i32 42

@external_le = external thread_local(localexec) global i32
@internal_le = internal thread_local(localexec) global i32 42

; ----- no model specified -----

define i32* @f1() {
; PIC: f1:
; STATIC: f1:

entry:
  ret i32* @external_gd

  ; Non-PIC code can use initial-exec, PIC code has to use general dynamic.
  ; PIC: moveli [[REG0:r[0-9]+]], hw1_last_tls_gd(external_gd)
  ; PIC: shl16insli [[REG1:r[0-9]+]], [[REG0]], hw0_tls_gd(external_gd)
  ; PIC: addi r0, r51, tls_add(external_gd)
  ; PIC: jal tls_gd_call(external_gd)
  ; PIC: addi {{r[0-9]+}}, r0, tls_gd_add(external_gd)

  ; STATIC: moveli [[REG0:r[0-9]+]], hw1_last_tls_ie(external_gd)
  ; STATIC: shl16insli [[REG1:r[0-9]+]], [[REG0]], hw0_tls_ie(external_gd)
  ; STATIC: addi r{{[0-9]+}}, r51, tls_add(external_gd)
  ; STATIC: ld_tls r{{[0-9]+}}, r{{[0-9]+}}, tls_ie_load(external_gd)
  ; STATIC: add r{{[0-9]+}}, r{{[0-9]+}}, tp
}

define i32* @f2() {
; PIC: f2:
; STATIC: f2:

entry:
  ret i32* @internal_gd

  ; Non-PIC code can use local exec, PIC code can use general dynamic.
  ; PIC: moveli [[REG0:r[0-9]+]], hw1_last_tls_gd(internal_gd)
  ; PIC: shl16insli [[REG1:r[0-9]+]], [[REG0]], hw0_tls_gd(internal_gd)
  ; PIC: addi r0, r51, tls_add(internal_gd)
  ; PIC: jal tls_gd_call(internal_gd)
  ; PIC: addi {{r[0-9]+}}, r0, tls_gd_add(internal_gd)

  ; STATIC: moveli [[REG0:r[0-9]+]], hw1_last_tls_le(internal_gd)
  ; STATIC: shl16insli [[REG1:r[0-9]+]], [[REG0]], hw0_tls_le(internal_gd)
  ; STATIC: add r{{[0-9]+}}, [[REG1]], tp
}


; ----- initialexec specified -----

define i32* @f3() {
; PIC: f3:
; STATIC: f3:

entry:
  ret i32* @external_ie

  ; Non-PIC and PIC code will use initial exec as specified.
  ; PIC: moveli [[REG0:r[0-9]+]], hw1_last_tls_ie(external_ie)
  ; PIC: shl16insli [[REG1:r[0-9]+]], [[REG0]], hw0_tls_ie(external_ie)
  ; PIC: addi r{{[0-9]+}}, r51, tls_add(external_ie)
  ; PIC: ld_tls r{{[0-9]+}}, r{{[0-9]+}}, tls_ie_load(external_ie)
  ; PIC: add r{{[0-9]+}}, r{{[0-9]+}}, tp

  ; STATIC: moveli [[REG0:r[0-9]+]], hw1_last_tls_ie(external_ie)
  ; STATIC: shl16insli [[REG1:r[0-9]+]], [[REG0]], hw0_tls_ie(external_ie)
  ; STATIC: addi r{{[0-9]+}}, r51, tls_add(external_ie)
  ; STATIC: ld_tls r{{[0-9]+}}, r{{[0-9]+}}, tls_ie_load(external_ie)
  ; STATIC: add r{{[0-9]+}}, r{{[0-9]+}}, tp
}

define i32* @f4() {
; PIC: f4:
; STATIC: f4:

entry:
  ret i32* @internal_ie

  ; Non-PIC code can use local exec, PIC code use initial exec as specified.
  ; PIC: moveli [[REG0:r[0-9]+]], hw1_last_tls_ie(internal_ie)
  ; PIC: shl16insli [[REG1:r[0-9]+]], [[REG0]], hw0_tls_ie(internal_ie)
  ; PIC: addi r{{[0-9]+}}, r51, tls_add(internal_ie)
  ; PIC: ld_tls r{{[0-9]+}}, r{{[0-9]+}}, tls_ie_load(internal_ie)
  ; PIC: add r{{[0-9]+}}, r{{[0-9]+}}, tp

  ; STATIC: moveli [[REG0:r[0-9]+]], hw1_last_tls_le(internal_ie)
  ; STATIC: shl16insli [[REG1:r[0-9]+]], [[REG0]], hw0_tls_le(internal_ie)
  ; STATIC: add r{{[0-9]+}}, [[REG1]], tp
}


; ----- localexec specified -----

define i32* @f5() {
; PIC: f5:
; STATIC: f5:

entry:
  ret i32* @external_le

  ; Non-PIC and PIC code will use local exec as specified.
  ; PIC: moveli [[REG0:r[0-9]+]], hw1_last_tls_le(external_le)
  ; PIC: shl16insli [[REG1:r[0-9]+]], [[REG0]], hw0_tls_le(external_le)
  ; PIC: add r{{[0-9]+}}, [[REG1]], tp

  ; STATIC: moveli [[REG0:r[0-9]+]], hw1_last_tls_le(external_le)
  ; STATIC: shl16insli [[REG1:r[0-9]+]], [[REG0]], hw0_tls_le(external_le)
  ; STATIC: add r{{[0-9]+}}, [[REG1]], tp
}

define i32* @f6() {
; PIC: f6:
; STATIC: f6:

entry:
  ret i32* @internal_le

  ; Non-PIC and PIC code will use local exec as specified.
  ; PIC: moveli [[REG0:r[0-9]+]], hw1_last_tls_le(internal_le)
  ; PIC: shl16insli [[REG1:r[0-9]+]], [[REG0]], hw0_tls_le(internal_le)
  ; PIC: add r{{[0-9]+}}, [[REG1]], tp

  ; STATIC: moveli [[REG0:r[0-9]+]], hw1_last_tls_le(internal_le)
  ; STATIC: shl16insli [[REG1:r[0-9]+]], [[REG0]], hw0_tls_le(internal_le)
  ; STATIC: add r{{[0-9]+}}, [[REG1]], tp
}
