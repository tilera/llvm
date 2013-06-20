	.file	"/home/jiwang/GitHub/llvm/test/CodeGen/Tile/fcmp.ll"
	.section	.rodata.cst4,"aM",@progbits,4
	.align	4
.LCPI0_0:
	.4byte	1065353216              # float 1
	.text
	.globl	f0
	.align	8
	.type	f0,@function
f0:                                     # @f0
	.cfi_startproc
# BB#0:                                 # %entry
	addi sp, sp, -8
.Ltmp1:
	.cfi_def_cfa_offset 8
	moveli r1, hw2_last(.LCPI0_0)
	shl16insli r1, r1, hw1(.LCPI0_0)
	shl16insli r1, r1, hw0(.LCPI0_0)
	ld4s r2, r1
	fsingle_add1 r2, r0, r2
	bfextu r2, r2, 30, 30
	addi r49, sp, 4
	st4 r49, r0
	addx r0, zero, r2
	addi sp, sp, 8
	jr	lr
.Ltmp2:
	.size	f0, .Ltmp2-f0
	.cfi_endproc

	.section	.rodata.cst4,"aM",@progbits,4
	.align	4
.LCPI1_0:
	.4byte	1065353216              # float 1
	.text
	.globl	f1
	.align	8
	.type	f1,@function
f1:                                     # @f1
	.cfi_startproc
# BB#0:                                 # %entry
	addi sp, sp, -8
.Ltmp4:
	.cfi_def_cfa_offset 8
	moveli r1, hw2_last(.LCPI1_0)
	shl16insli r1, r1, hw1(.LCPI1_0)
	shl16insli r1, r1, hw0(.LCPI1_0)
	ld4s r2, r1
	fsingle_add1 r2, r0, r2
	bfextu r2, r2, 26, 26
	addi r49, sp, 4
	st4 r49, r0
	addx r0, zero, r2
	addi sp, sp, 8
	jr	lr
.Ltmp5:
	.size	f1, .Ltmp5-f1
	.cfi_endproc

	.section	.rodata.cst4,"aM",@progbits,4
	.align	4
.LCPI2_0:
	.4byte	1065353216              # float 1
	.text
	.globl	f2
	.align	8
	.type	f2,@function
f2:                                     # @f2
	.cfi_startproc
# BB#0:                                 # %entry
	addi sp, sp, -8
.Ltmp7:
	.cfi_def_cfa_offset 8
	moveli r1, hw2_last(.LCPI2_0)
	shl16insli r1, r1, hw1(.LCPI2_0)
	shl16insli r1, r1, hw0(.LCPI2_0)
	ld4s r2, r1
	fsingle_add1 r2, r0, r2
	bfextu r2, r2, 27, 27
	addi r49, sp, 4
	st4 r49, r0
	addx r0, zero, r2
	addi sp, sp, 8
	jr	lr
.Ltmp8:
	.size	f2, .Ltmp8-f2
	.cfi_endproc

	.section	.rodata.cst4,"aM",@progbits,4
	.align	4
.LCPI3_0:
	.4byte	1065353216              # float 1
	.text
	.globl	f3
	.align	8
	.type	f3,@function
f3:                                     # @f3
	.cfi_startproc
# BB#0:                                 # %entry
	addi sp, sp, -8
.Ltmp10:
	.cfi_def_cfa_offset 8
	moveli r1, hw2_last(.LCPI3_0)
	shl16insli r1, r1, hw1(.LCPI3_0)
	shl16insli r1, r1, hw0(.LCPI3_0)
	ld4s r2, r1
	fsingle_add1 r2, r0, r2
	bfextu r2, r2, 28, 28
	addi r49, sp, 4
	st4 r49, r0
	addx r0, zero, r2
	addi sp, sp, 8
	jr	lr
.Ltmp11:
	.size	f3, .Ltmp11-f3
	.cfi_endproc

	.section	.rodata.cst4,"aM",@progbits,4
	.align	4
.LCPI4_0:
	.4byte	1065353216              # float 1
	.text
	.globl	f4
	.align	8
	.type	f4,@function
f4:                                     # @f4
	.cfi_startproc
# BB#0:                                 # %entry
	addi sp, sp, -8
.Ltmp13:
	.cfi_def_cfa_offset 8
	moveli r1, hw2_last(.LCPI4_0)
	shl16insli r1, r1, hw1(.LCPI4_0)
	shl16insli r1, r1, hw0(.LCPI4_0)
	ld4s r2, r1
	fsingle_add1 r2, r0, r2
	bfextu r2, r2, 29, 29
	addi r49, sp, 4
	st4 r49, r0
	addx r0, zero, r2
	addi sp, sp, 8
	jr	lr
.Ltmp14:
	.size	f4, .Ltmp14-f4
	.cfi_endproc

	.section	.rodata.cst8,"aM",@progbits,8
	.align	8
.LCPI5_0:
	.quad	4607182418800017408     # double 1
	.text
	.globl	f5
	.align	8
	.type	f5,@function
f5:                                     # @f5
	.cfi_startproc
# BB#0:                                 # %entry
	addi sp, sp, -8
.Ltmp16:
	.cfi_def_cfa_offset 8
	moveli r1, hw2_last(.LCPI5_0)
	shl16insli r1, r1, hw1(.LCPI5_0)
	shl16insli r1, r1, hw0(.LCPI5_0)
	ld r1, r1
	fdouble_add_flags r2, r0, r1
	bfextu r2, r2, 30, 30
	addi r49, sp, 0
	st r49, r0
	addx r0, zero, r2
	addi sp, sp, 8
	jr	lr
.Ltmp17:
	.size	f5, .Ltmp17-f5
	.cfi_endproc

	.section	.rodata.cst8,"aM",@progbits,8
	.align	8
.LCPI6_0:
	.quad	4607182418800017408     # double 1
	.text
	.globl	f6
	.align	8
	.type	f6,@function
f6:                                     # @f6
	.cfi_startproc
# BB#0:                                 # %entry
	addi sp, sp, -8
.Ltmp19:
	.cfi_def_cfa_offset 8
	moveli r1, hw2_last(.LCPI6_0)
	shl16insli r1, r1, hw1(.LCPI6_0)
	shl16insli r1, r1, hw0(.LCPI6_0)
	ld r1, r1
	fdouble_add_flags r2, r0, r1
	bfextu r2, r2, 26, 26
	addi r49, sp, 0
	st r49, r0
	addx r0, zero, r2
	addi sp, sp, 8
	jr	lr
.Ltmp20:
	.size	f6, .Ltmp20-f6
	.cfi_endproc

	.section	.rodata.cst8,"aM",@progbits,8
	.align	8
.LCPI7_0:
	.quad	4607182418800017408     # double 1
	.text
	.globl	f7
	.align	8
	.type	f7,@function
f7:                                     # @f7
	.cfi_startproc
# BB#0:                                 # %entry
	addi sp, sp, -8
.Ltmp22:
	.cfi_def_cfa_offset 8
	moveli r1, hw2_last(.LCPI7_0)
	shl16insli r1, r1, hw1(.LCPI7_0)
	shl16insli r1, r1, hw0(.LCPI7_0)
	ld r1, r1
	fdouble_add_flags r2, r0, r1
	bfextu r2, r2, 27, 27
	addi r49, sp, 0
	st r49, r0
	addx r0, zero, r2
	addi sp, sp, 8
	jr	lr
.Ltmp23:
	.size	f7, .Ltmp23-f7
	.cfi_endproc

	.section	.rodata.cst8,"aM",@progbits,8
	.align	8
.LCPI8_0:
	.quad	4607182418800017408     # double 1
	.text
	.globl	f8
	.align	8
	.type	f8,@function
f8:                                     # @f8
	.cfi_startproc
# BB#0:                                 # %entry
	addi sp, sp, -8
.Ltmp25:
	.cfi_def_cfa_offset 8
	moveli r1, hw2_last(.LCPI8_0)
	shl16insli r1, r1, hw1(.LCPI8_0)
	shl16insli r1, r1, hw0(.LCPI8_0)
	ld r1, r1
	fdouble_add_flags r2, r0, r1
	bfextu r2, r2, 28, 28
	addi r49, sp, 0
	st r49, r0
	addx r0, zero, r2
	addi sp, sp, 8
	jr	lr
.Ltmp26:
	.size	f8, .Ltmp26-f8
	.cfi_endproc

	.section	.rodata.cst8,"aM",@progbits,8
	.align	8
.LCPI9_0:
	.quad	4607182418800017408     # double 1
	.text
	.globl	f9
	.align	8
	.type	f9,@function
f9:                                     # @f9
	.cfi_startproc
# BB#0:                                 # %entry
	addi sp, sp, -8
.Ltmp28:
	.cfi_def_cfa_offset 8
	moveli r1, hw2_last(.LCPI9_0)
	shl16insli r1, r1, hw1(.LCPI9_0)
	shl16insli r1, r1, hw0(.LCPI9_0)
	ld r1, r1
	fdouble_add_flags r2, r0, r1
	bfextu r2, r2, 29, 29
	addi r49, sp, 0
	st r49, r0
	addx r0, zero, r2
	addi sp, sp, 8
	jr	lr
.Ltmp29:
	.size	f9, .Ltmp29-f9
	.cfi_endproc

	.section	.rodata.cst4,"aM",@progbits,4
	.align	4
.LCPI10_0:
	.4byte	1065353216              # float 1
	.text
	.globl	f10
	.align	8
	.type	f10,@function
f10:                                    # @f10
	.cfi_startproc
# BB#0:                                 # %entry
	addi sp, sp, -8
.Ltmp31:
	.cfi_def_cfa_offset 8
	moveli r1, hw2_last(.LCPI10_0)
	shl16insli r1, r1, hw1(.LCPI10_0)
	shl16insli r1, r1, hw0(.LCPI10_0)
	ld4s r2, r1
	fsingle_add1 r2, r0, r2
	bfextu r2, r2, 31, 31
	addi r49, sp, 4
	st4 r49, r0
	addx r0, zero, r2
	addi sp, sp, 8
	jr	lr
.Ltmp32:
	.size	f10, .Ltmp32-f10
	.cfi_endproc

	.section	.rodata.cst8,"aM",@progbits,8
	.align	8
.LCPI11_0:
	.quad	4607182418800017408     # double 1
	.text
	.globl	f11
	.align	8
	.type	f11,@function
f11:                                    # @f11
	.cfi_startproc
# BB#0:                                 # %entry
	addi sp, sp, -8
.Ltmp34:
	.cfi_def_cfa_offset 8
	moveli r1, hw2_last(.LCPI11_0)
	shl16insli r1, r1, hw1(.LCPI11_0)
	shl16insli r1, r1, hw0(.LCPI11_0)
	ld r1, r1
	fdouble_add_flags r2, r0, r1
	bfextu r2, r2, 31, 31
	addi r49, sp, 0
	st r49, r0
	addx r0, zero, r2
	addi sp, sp, 8
	jr	lr
.Ltmp35:
	.size	f11, .Ltmp35-f11
	.cfi_endproc


