	.file	"main.c"
	.text
	.globl	main
	.align	2
	.type	main,@function
main:
	addi	x2, x2, -24
	sd	x8, 16(x2)
	add	x8, x0, x2
	sw	x0, 12(x8)
	sw	x0, 8(x8)
.LBB0_1:
	lw	x5, 8(x8)
	li	x6, 9
	blt	x6, x5, .LBB0_4
	j	.LBB0_2
.LBB0_2:
	lw	x5, 8(x8)
	lw	x6, 4(x8)
	slliw	x5, x5, 1
	addw	x5, x6, x5
	sw	x5, 4(x8)
	lw	x5, 8(x8)
	addiw	x5, x5, 1
	sw	x5, 8(x8)
	j	.LBB0_1
.LBB0_4:
	lw	x10, 4(x8)
	add	x2, x0, x8
	ld	x8, 16(x2)
	addi	x2, x2, 24
	ret
.Ltmp3:
	.size	main, .Ltmp3-main


	.section	".note.GNU-stack","",@progbits
