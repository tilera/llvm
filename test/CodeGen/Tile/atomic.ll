; RUN: llc -march=tilegx < %s | FileCheck %s

define i32 @exchange_and_add32(i32* %mem, i32 %val) nounwind {
; CHECK: exchange_and_add32:

entry:
  %tmp = atomicrmw add i32* %mem, i32 %val monotonic
  ret i32 %tmp

; CHECK: fetchadd4
}

define i32 @exchange_and_cmp32(i32* %mem) nounwind {
; CHECK: exchange_and_cmp32:

entry:
  %tmp = cmpxchg i32* %mem, i32 0, i32 1 monotonic
  ret i32 %tmp

; CHECK: mtspr CMPEXCH_VALUE
; CHECK: cmpexch4
}

define i32 @exchange32(i32* %mem, i32 %val) nounwind {
; CHECK: exchange32:

entry:
  %tmp = atomicrmw xchg i32* %mem, i32 1 monotonic
  ret i32 %tmp

; CHECK: movei r{{[0-9]+}}, 1
; CHECK: exch4
}

define void @atomic_store32(i32* %mem, i32 %val) nounwind {
; CHECK: atomic_store32:

entry:
  store atomic i32 %val, i32* %mem release, align 64
  ret void

; CHECK: exch4
}

define i32 @atomic_load32(i32* %mem) nounwind {
; CHECK: atomic_load32:

entry:
  %tmp = load atomic i32* %mem acquire, align 64
  ret i32 %tmp

; CHECK: mtspr CMPEXCH_VALUE
; CHECK: cmpexch4
}

define i64 @exchange_and_add(i64* %mem, i64 %val) nounwind {
; CHECK: exchange_and_add:

entry:
  %tmp = atomicrmw add i64* %mem, i64 %val monotonic
  ret i64 %tmp

; CHECK: fetchadd
}

define i64 @exchange_and_cmp(i64* %mem) nounwind {
; CHECK: exchange_and_cmp:

entry:
  %tmp = cmpxchg i64* %mem, i64 0, i64 1 monotonic
  ret i64 %tmp

; CHECK: mtspr CMPEXCH_VALUE
; CHECK: cmpexch
}

define i64 @exchange(i64* %mem, i64 %val) nounwind {
; CHECK: exchange:

entry:
  %tmp = atomicrmw xchg i64* %mem, i64 1 monotonic
  ret i64 %tmp

; CHECK: movei r{{[0-9]+}}, 1
; CHECK: exch
}

define void @atomic_store(i64* %mem, i64 %val) nounwind {
; CHECK: atomic_store:

entry:
  store atomic i64 %val, i64* %mem release, align 64
  ret void

; CHECK: exch
}

define i64 @atomic_load(i64* %mem) nounwind {
; CHECK: atomic_load:

entry:
  %tmp = load atomic i64* %mem acquire, align 64
  ret i64 %tmp

; CHECK: mtspr CMPEXCH_VALUE
; CHECK: cmpexch
}
