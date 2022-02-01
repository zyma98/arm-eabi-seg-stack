/**
 * mem*() function implementation intended to use with
 * segmented stack (-fsplit-stack) on ARM EABI.
 *
 * These functions should *NOT* consume any stack space.
 * Compiler intrinsic functions may call these functions.
 * However, these functions do not check stacklet overflow
 * nor allocate new stacklet, because stacklet allocation
 * functions may call these functions through compiler
 * intrinsic functions.
 *
 * Example: __morestack    : will allocate a new chunk
 *       -> __malloc       : will set the bit map
 *       -> __aeabi_memset : compiler invoked intrinsic
 *       -> memset         : SHOULD NOT CALL __morestack
 *
 * Author: Zhiyao Ma <zhiyao.ma@yale.edu>.
 */
	.text
	.syntax unified
	.cpu	cortex-m4
	.eabi_attribute	14, 1
	.file	"memops.S"
	.globl	memset
	.p2align	1
	.type	memset,%function
	.code	16
	.thumb_func
memset:
	.fnstart
	cbz	r2, .Lmemset_ret
	mov	r3, r0
	.p2align	2
.Lmemset_loop:
	subs	r2, #1
	strb	r1, [r3], #1
	bne	.Lmemset_loop
.Lmemset_ret:
	bx	lr
.Lmemset_end:
	.size	memset, .Lmemset_end-memset
	.cantunwind
	.fnend

	.globl	memclr
	.p2align	1
	.type	memclr,%function
	.code	16
	.thumb_func
memclr:
	.fnstart
	mov	r2, r1
	eors r1, r1
	b	memset
.Lmemclr_end:
	.size	memclr, .Lmemclr_end-memclr
	.cantunwind
	.fnend
	.section	".note.GNU-stack","",%progbits
	.addrsig
	.eabi_attribute	30, 3
