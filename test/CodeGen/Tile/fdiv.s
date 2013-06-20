	.file	"/home/jiwang/GitHub/llvm/test/CodeGen/Tile/fdiv.ll"
	.text
	.globl	test0
	.align	8
	.type	test0,@function
test0:                                  # @test0
	.cfi_startproc
# BB#0:                                 # %entry
	add r11, sp, zero
	st sp, lr
.Ltmp2:
	.cfi_offset 55, 0
	addi	sp, sp, -32
	addi	r10, sp, 8
	st r10, r11
.Ltmp3:
	.cfi_def_cfa_offset 32
	addi	r49, sp, 28
	st4 r49, r0
	addi	r49, sp, 24
	st4 r49, r1
	jal	__divsf3
	addi	r49, sp, 24
	ld4s r1, r49
	addi	r49, sp, 28
	ld4s r2, r49
	addi	r49, sp, 20
	st4 r49, r2
	addi	r49, sp, 16
	st4 r49, r1
	addi	sp, sp, 32
	ld lr, sp
	jr	lr
.Ltmp4:
	.size	test0, .Ltmp4-test0
	.cfi_endproc

	.section	.rodata.cst4,"aM",@progbits,4
	.align	4
.LCPI1_0:
	.4byte	1073741824              # float 2
	.text
	.globl	test1
	.align	8
	.type	test1,@function
test1:                                  # @test1
# BB#0:                                 # %entry
	add r11, sp, zero
	st sp, lr
	addi	sp, sp, -24
	addi	r10, sp, 8
	st r10, r11
	moveli r1, hw2_last(.LCPI1_0)
	shl16insli r1, r1, hw1(.LCPI1_0)
	shl16insli r1, r1, hw0(.LCPI1_0)
	ld4s r1, r1
	addi	r49, sp, 20
	st4 r49, r0
	jal	__divsf3
	addi	r49, sp, 20
	ld4s r1, r49
	addi	r49, sp, 16
	st4 r49, r1
	addi	sp, sp, 24
	ld lr, sp
	jr	lr
.Ltmp7:
	.size	test1, .Ltmp7-test1

	.globl	test2
	.align	8
	.type	test2,@function
test2:                                  # @test2
	.cfi_startproc
# BB#0:                                 # %entry
	add r11, sp, zero
	st sp, lr
.Ltmp10:
	.cfi_offset 55, 0
	addi	sp, sp, -48
	addi	r10, sp, 8
	st r10, r11
.Ltmp11:
	.cfi_def_cfa_offset 48
	addi	r49, sp, 40
	st r49, r0
	addi	r49, sp, 32
	st r49, r1
	jal	__divdf3
	addi	r49, sp, 32
	ld r1, r49
	addi	r49, sp, 40
	ld r2, r49
	addi	r49, sp, 24
	st r49, r2
	addi	r49, sp, 16
	st r49, r1
	addi	sp, sp, 48
	ld lr, sp
	jr	lr
.Ltmp12:
	.size	test2, .Ltmp12-test2
	.cfi_endproc

	.section	.rodata.cst8,"aM",@progbits,8
	.align	8
.LCPI3_0:
	.quad	4611686018427387904     # double 2
	.text
	.globl	test3
	.align	8
	.type	test3,@function
test3:                                  # @test3
# BB#0:                                 # %entry
	add r11, sp, zero
	st sp, lr
	addi	sp, sp, -32
	addi	r10, sp, 8
	st r10, r11
	moveli r1, hw2_last(.LCPI3_0)
	shl16insli r1, r1, hw1(.LCPI3_0)
	shl16insli r1, r1, hw0(.LCPI3_0)
	ld r1, r1
	addi	r49, sp, 24
	st r49, r0
	jal	__divdf3
	addi	r49, sp, 24
	ld r1, r49
	addi	r49, sp, 16
	st r49, r1
	addi	sp, sp, 32
	ld lr, sp
	jr	lr
.Ltmp15:
	.size	test3, .Ltmp15-test3


