#include "asm.h"

.equ    KERNEL, 0
.equ    USER,   156

.macro STI
.endm

.macro CLI
.endm

LEAF(asm_start)
    mtc0    zero, CP0_STATUS
    mtc0    zero, CP0_WATCHLO
    mtc0    zero, CP0_WATCHHI

    mfc0    t0, CP0_CONFIG
    and     t0, ~0x7
    ori     t0, 0x2
    mtc0    t0, CP0_CONFIG
    
    jr  ra
END(asm_start)

.macro SAVE_CONTEXT offset
    // TODO save context
	sw		t0, (sp)
	lw		t0, current_running
	#addi	t0, t0, \offset 
	sw		AT,   4(t0)
	sw		v0,   8(t0)
	sw		v1,  12(t0)
	sw		a0,  16(t0)
	sw		a1,  20(t0)
	sw		a2,  24(t0)
	sw		a3,  28(t0)
	#sw		t0,  32(t0)
	sw		t1,  36(t0)
	sw		t2,  40(t0)
	sw		t3,  44(t0)
	sw		t4,  48(t0)
	sw		t5,  52(t0)
	sw		t6,  56(t0)
	sw		t7,  60(t0)
	sw		s0,  64(t0)
	sw		s1,  68(t0)
	sw		s2,  72(t0)
	sw		s3,  76(t0)
	sw		s4,  80(t0)
	sw		s5,  84(t0)
	sw		s6,  88(t0)
	sw		s7,  92(t0)
	sw		t8,  96(t0)
	sw		t9, 100(t0)
	sw		gp, 112(t0)
	sw		sp, 116(t0)
	sw		fp, 120(t0)
	sw		ra, 124(t0)
	lw		t1, (sp)
	sw		t1,  32(t0)
	nop
.endm

.macro RESTORE_CONTEXT offset
    // TODO restore context
	lw		t0,current_running
	#addi	t0, t0, \offset 
	lw		AT,4(t0)
	lw		v0,8(t0)
	lw		v1,12(t0)	
	lw		a0,16(t0)
	lw		a1,20(t0)
	lw		a2,24(t0)
	lw		a3,28(t0)
	lw		t1,36(t0)
	lw		t2,40(t0)
	lw		t3,44(t0)
	lw		t4,48(t0)
	lw		t5,52(t0)
	lw		t6,56(t0)
	lw		t7,60(t0)
	lw		s0,64(t0)
	lw		s1,68(t0)
	lw		s2,72(t0)
	lw		s3,76(t0)
	lw		s4,80(t0)
	lw		s5,84(t0)
	lw		s6,88(t0)
	lw		s7,92(t0)
	lw		t8,96(t0)
	lw		t9,100(t0)
	lw		gp,112(t0)
	lw		sp,116(t0)
	lw		fp,120(t0)
	lw		ra,124(t0)
	lw		t0,32(t0)
	nop
.endm

NESTED(do_scheduler, 0, ra)
    SAVE_CONTEXT(KERNEL)
    jal     scheduler
    RESTORE_CONTEXT(KERNEL)
    jr      ra
END(do_scheduler)

.global exception_handler_begin
.global exception_handler_end

NESTED(exception_handler_entry, 0, sp)   
exception_handler_begin:
    // TODO close interrupt
    // jmp exception_handler[i] which decided by CP0_CAUSE
    // Leve2 exception Handler.
exception_handler_end:
END(exception_handler_entry)

NESTED(handle_int, 0, sp)
    // interrupt handler
    // Leve3 exception Handler.
END(handle_int)

NESTED(handle_syscall, 0, sp)
    // system call handler
END(handle_syscall)

NESTED(handle_other, 0, sp)
    // other exception handler
END(handle_other)


