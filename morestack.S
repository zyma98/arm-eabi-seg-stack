/** 
 * ARM EABI support for -fsplit-stack.
 * Author: Zhiyao Ma <zhiyao.ma@yale.edu>.
 */
	.text
	.syntax unified
	.cpu	cortex-m4
	.eabi_attribute	14, 1
	.file	"morestack.S"
	.globl	__morestack
	.globl	__morestack_non_split
	.type	__morestack,%function
	.type	__morestack_non_split,%function
	.p2align	1
	.code	16
	.thumb_func
__morestack_non_split:
__morestack:

/**
 * An implementation of segmented stack on ARM MCU.
 * It conforms to the following ABI extended from
 * the RWPI (read-write position independence)
 * relocation model.
 *
 * ABI description:
 * 1. R4 stores the requested stack frame size.
 * 2. R5 stores the caller's argument size.
 * 3. R4 and R5 may be used as scratch registers.
 * 4. *ALL* other registers must be preserved other than
 *    PC and SP.
 * 5. R9 must point to the extended static base, as
 *    shown below.
 *
 *  --------------------------------------------------
 *  | Temp Stack |  Stacklet  |  Scratch   |  .DATA  ...
 *  |   Pointer  |  Boundary  |   Space    |  + .BSS ...
 *  --------------------------------------------------
 *  ^            ^            ^            ^
 *  R9 - 12      R9 - 8       R9 - 4       R9
 *
 * - Stacklet boundary stores the address that SP in
 *   user code must never go below.
 * - Temp stack is the stack used during stacklet
 *   allocation and free. The temp stack *MUST* be
 *   cleared before going back to user code, because
 *   later re-entrant invocation of __morestack
 *   will also use temp stack.
 * - The scratch space is used to preserve the
 *   current user sp across __malloc invocation.
 * - R9 must point to the static base (RWPI requirement).
 *
 * Allocated stacklets form a linked list. A newer
 * stacklet stores information that points back to
 * the previous one. The stacklet layout is shown below.
 *
 * |---------------------------|
 * |    Function Arguments     |
 * |     And Stack Frames      |
 * |                           |
 * |---------------------------| <- Stacklet Boundary
 * | Prev. LR to User Prologue |
 * |---------------------------|
 * |    Prev. Stack Pointer    |
 * |---------------------------|
 * |  Prev. Stacklet Boundary  |
 * |---------------------------| <- __malloc() Return Val
 */
	.fnstart

	// Store the current user stack to the scratch space
	// and switch to the temp stack.
	str		sp, [r9, #-4]
	ldr		sp, [r9, #-12]

	// Save user function arguments.
	push	{r0, r1, r2, r3}

	// Preserve the return address to the user function prologue.
	push	{lr}

	// Allocate a new stacklet.
	adds	r0, r4, r5  // r4 holds requested stack frame size
	    	            // r5 holds stack arguments size
						// r0 now is the total requested size

	adds	r0, #32     // 12 bytes to save the link to the
	    	            // previous stacklet.
						// 12 bytes for the user function
						// prologue to push r4, r5 and lr.
						// 8 bytes to store the copied
						// r4 and r5, which will be popped
						// at the beginning of user function
						// body.
						// In total we need additional
						// 32 bytes.
	bl		__malloc

	// Save the old stacklet information into the new stacklet.
	ldmdb	r9, {r1, r2}      // r1 now holds prev. stacklet boundary
	     	                  // r2 now holds prev. stack pointer
	pop		{r3}              // r3 now holds prev. LR
	stmia	r0!, {r1, r2, r3} // Store r1-r3 to the new stacklet
	     	                  // r0 is also incremented by 12 bytes

	// Update the stacklet boundary.
	str		r0, [r9, #-8]  // now r0 is the new stacklet boundary
	   		               // store it to the extended static base

	adds	r4, #12 // Make sure additional 12 bytes will be
	    	        // under sp for further called function
					// to save r4, r5 and lr in its prologue.

	adds	r4, r0  // move r0 up, skip r4 bytes
	                // now r4 points to the address where stack
					// arguments should be copied

	// The previous stacklet layout looks like below:
	//
	// |           ... ...           |
	// |  Caller's Func Stack Frame  |
	// |-----------------------------|
	// | Stack Arguments for Callee  |
	// |-----------------------------|
	// |  Callee Prologue Saved R5   |
	// |-----------------------------|
	// |  Callee Prologue Saved R4   |
	// |-----------------------------|
	// |  Callee Prologue Saved LR   |
	// |-----------------------------| <- r2 pointing here
	//
	//
	// After copying arguments, the callee's body expects
	// the stacklet layout below:
	//
	// |-----------------------------|
	// | Stack Arguments for Callee  |
	// |-----------------------------|
	// |  Callee Prologue Saved R5   |
	// |-----------------------------|
	// |  Callee Prologue Saved R4   |
	// |-----------------------------| <- sp will point here
	// |           ... ...           |    (now r4 pointing here)
	// |  Enough for Callee's Frame  |
	// |    Plus 12 Bytes for The    |
	// | Prologue of Callee's Callee |
	// |    to Store R4, R5, LR      |
	// |           ... ...           |
	// |-----------------------------| <- Stacklet Boundary
	// |  Prev. LR to User Prologue  |    stored at [r9, #-8]
	// |-----------------------------|
	// |     Prev. Stack Pointer     |
	// |-----------------------------|
	// |   Prev. Stacklet Boundary   |
	// |-----------------------------|

	adds	r2, #4         // skip callee prologue pushed lr
	ldmia	r2!, {r0, r1}  // read callee prologue pushed r4, r5
	stmia	r4!, {r0, r1}  // and save them to the new stacklet

	// Copy stack arguments, from high address to low address.
	// r5 counts the number of remaining bytes.
	// r2 points to the arguments in the old stacklet.
	// r4 points to the start of arguments in the new stacklet.
	adds	r2, r5        // move r2 to the end of the arguments
.Lloop_predicate:
	cbz		r5, .Lloop_done
	ldmdb	r2!, {r1}     // load an argument into r1
	subs	r5, #4        // decrement the counter here
	str		r1, [r4, r5]  // to avoid a load-store hazard here
	b		.Lloop_predicate
.Lloop_done:

	// Prepare to call into user function body.
	add		r5, r3, #8  // r3 holds the return address to the
	   		            // user function prologue
						// r5 now points to the user function body

	// Restore user arguments. 
	pop		{r0, r1, r2, r3}

	// *IMPORTANT* Note that the temp stack has been emptied.

	// Move down 8 bytes so that later sp will point to
	// the prologue-saved r4 and r5.
	subs	r4, #8

	// Switch to the new stacklet.
	mov		sp, r4

	// Call into the user function body.
	blx		r5

	// Switch to the temp stack.
	ldr		sp, [r9, #-12]

	// Save user return values.
	push	{r0, r1}

	// Get the current stacklet boundary.
	ldr		r0, [r9, #-8]

	// Retrieve information about the previous stacklet.
	ldmdb	r0!, {r3, r4, r5}  // Load 12 bytes below r0 into
	     	                   // r3-r5. r0 is also decremented
							   // by 12 bytes.

	// Update the stacklet boundary in the extended static base.
	str		r3, [r9, #-8]

	// Free the stacklet.
	bl		__free  // r0 is pointing to the allocated chunk.

	// Restore user return value.
	pop		{r0, r1}

	// Switch back to the old stacklet
	mov		sp, r4

	// Return to the caller's prologue
	bx		r5

.L__morestack_end:
	.size	__morestack, .L__morestack_end-__morestack
	.cantunwind
	.fnend
	.section	".note.GNU-stack","",%progbits
	.addrsig
