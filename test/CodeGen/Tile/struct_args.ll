; RUN: llc -march=tilegx -relocation-model=static < %s | FileCheck %s

declare void @bar(i64)

%struct.small = type { i32, i32 }

@s1 = common global %struct.small zeroinitializer, align 4

define void @foo() nounwind {
; CHECK: foo:

entry:
  %0 = load i64* bitcast (%struct.small* @s1 to i64*), align 1
  call void @bar(i64 %0)
  ret void

; CHECK: shl16insli [[REG0:r[0-9]+]], r{{[0-9]+}}, hw1(s1)
; CHECK: shl16insli [[REG1:r[0-9]+]], [[REG0]], hw0(s1)
; CHECK: addi [[REG2:r[0-9]+]], [[REG1]], 4
; CHECK: shli r{{[0-9]+}}, [[REG2]], 32
}

%struct.large = type { i64, i64 }

@s2 = common global %struct.large zeroinitializer, align 8

define void @foo1() nounwind {
; CHECK: foo1:

entry:
  call void @bar1(%struct.large* byval @s2)
  ret void

; CHECK: shl16insli [[REG0:r[0-9]+]], r{{[0-9]+}}, hw1(s2)
; CHECK: shl16insli [[REG1:r[0-9]+]], [[REG0]], hw0(s2)
; pass the struct val by the first two arg regs.
; CHECK: addi [[REG2:r[0-9]+]], [[REG1]], 8
; CHECK: ld r1, [[REG2]]
}

declare void @bar1(%struct.large* byval)
