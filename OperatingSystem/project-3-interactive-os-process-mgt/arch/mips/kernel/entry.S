#include "asm.h"
#define TIMER_INTERVAL 100000000

.equ    KERNEL, 0
.equ    USER,   156

.macro STI
	mfc0    k0, CP0_STATUS
    ori     k0, k0, STATUS_IE
    mtc0    k0, CP0_STATUS
.endm

.macro CLI
	mfc0    k0, CP0_STATUS
    li      k1, ~STATUS_IE
    and	    k0, k0, k1
    mtc0    k0, CP0_STATUS
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
    # TODO save context
	lw		k0, current_running
	addi	k0, k0, \offset 
	sw		AT, OFFSET_REG1(k0)
	sw		v0, OFFSET_REG2(k0)
	sw		v1, OFFSET_REG3(k0)
	sw		a0, OFFSET_REG4(k0)
	sw		a1, OFFSET_REG5(k0)
	sw		a2, OFFSET_REG6(k0)
	sw		a3, OFFSET_REG7(k0)
	sw		t0, OFFSET_REG8(k0)
	sw		t1, OFFSET_REG9(k0)
	sw		t2, OFFSET_REG10(k0)
	sw		t3, OFFSET_REG11(k0)
	sw		t4, OFFSET_REG12(k0)
	sw		t5, OFFSET_REG13(k0)
	sw		t6, OFFSET_REG14(k0)
	sw		t7, OFFSET_REG15(k0)
	sw		s0, OFFSET_REG16(k0)
	sw		s1, OFFSET_REG17(k0)
	sw		s2, OFFSET_REG18(k0)
	sw		s3, OFFSET_REG19(k0)
	sw		s4, OFFSET_REG20(k0)
	sw		s5, OFFSET_REG21(k0)
	sw		s6, OFFSET_REG22(k0)
	sw		s7, OFFSET_REG23(k0)
	sw		t8, OFFSET_REG24(k0)
	sw		t9, OFFSET_REG25(k0)
	sw		gp, OFFSET_REG28(k0)
	sw		sp, OFFSET_REG29(k0)
	sw		fp, OFFSET_REG30(k0)
	sw		ra, OFFSET_REG31(k0)

	mfc0	k1, CP0_STATUS
	sw		k1, OFFSET_STATUS(k0)
	mfc0    k1, CP0_TAGHI
	sw		k1, OFFSET_HI(k0)
	mfc0    k1, CP0_TAGLO
	sw		k1, OFFSET_LO(k0)
	mfc0	k1, CP0_BADVADDR
	sw		k1, OFFSET_BADVADDR(k0)
	mfc0	k1, CP0_CAUSE
	sw		k1, OFFSET_CAUSE(k0)
	mfc0	k1, CP0_EPC
	sw		k1, OFFSET_EPC(k0)
.endm

.macro RESTORE_CONTEXT offset
    # TODO restore context
	lw		k0,current_running
	addi	k0, k0, \offset 
	lw		AT, OFFSET_REG1(k0)
	lw		v0, OFFSET_REG2(k0)
	lw		v1, OFFSET_REG3(k0)
	lw		a0, OFFSET_REG4(k0)
	lw		a1, OFFSET_REG5(k0)
	lw		a2, OFFSET_REG6(k0)
	lw		a3, OFFSET_REG7(k0)
	lw		t0, OFFSET_REG8(k0)
	lw		t1, OFFSET_REG9(k0)
	lw		t2, OFFSET_REG10(k0)
	lw		t3, OFFSET_REG11(k0)
	lw		t4, OFFSET_REG12(k0)
	lw		t5, OFFSET_REG13(k0)
	lw		t6, OFFSET_REG14(k0)
	lw		t7, OFFSET_REG15(k0)
	lw		s0, OFFSET_REG16(k0)
	lw		s1, OFFSET_REG17(k0)
	lw		s2, OFFSET_REG18(k0)
	lw		s3, OFFSET_REG19(k0)
	lw		s4, OFFSET_REG20(k0)
	lw		s5, OFFSET_REG21(k0)
	lw		s6, OFFSET_REG22(k0)
	lw		s7, OFFSET_REG23(k0)
	lw		t8, OFFSET_REG24(k0)
	lw		t9, OFFSET_REG25(k0)
	lw		gp, OFFSET_REG28(k0)
	lw		sp, OFFSET_REG29(k0)
	lw		fp, OFFSET_REG30(k0)
	lw		ra, OFFSET_REG31(k0)

	lw		k1, OFFSET_STATUS(k0)
	mtc0	k1, CP0_STATUS
	lw		k1, OFFSET_HI(k0)	
	mtc0    k1, CP0_TAGHI
	lw		k1, OFFSET_LO(k0)
	mtc0    k1, CP0_TAGLO
	lw		k1, OFFSET_BADVADDR(k0)
	mtc0	k1, CP0_BADVADDR
	lw		k1, OFFSET_CAUSE(k0)
	mtc0	k1, CP0_CAUSE
	lw		k1, OFFSET_EPC(k0)
	mtc0	k1, CP0_EPC
.endm

NESTED(do_scheduler, 0, ra)
    SAVE_CONTEXT(USER)
    jal     scheduler
	li		a0, TIMER_INTERVAL
	jal		reset_timer
    RESTORE_CONTEXT(USER)
    j		exception_over
END(do_scheduler)

NESTED(do_scheduler_without_save, 0, ra)
    jal     scheduler
	li		a0, TIMER_INTERVAL
	jal		reset_timer
    RESTORE_CONTEXT(KERNEL)
    j		exception_over
END(do_scheduler_without_save)

.global exception_handler_begin
.global exception_handler_end

NESTED(exception_handler_entry, 0, sp)   
exception_handler_begin:
    # TODO close interrupt
	CLI
	# jmp exception_handler[i] which decided by CP0_CAUSE
	# Leve2 exception Handler.
	mfc0	k0, CP0_CAUSE
	andi	k0, k0, CAUSE_EXCCODE	# k0 = {exc_code, 00}
	la		k1, exception_handler
	add		k0, k0, k1
	lw		k0, 0(k0)
	j		k0
exception_handler_end:
END(exception_handler_entry)

NESTED(handle_int, 0, sp)
    # interrupt handler
    # Leve3 exception Handler.
	SAVE_CONTEXT(USER)
	#jump to interrupt helper
	j		int_helper

int_helper:
	mfc0    k0, CP0_CAUSE
    andi    k0, k0, CAUSE_IPL
    li      k1, 0x8000
    beq     k1, k0, clock_interrupt    
	j		clear_int

clock_interrupt:
	la      k0, time_elapsed
    lw      k1, 0(k0)
    addi    k1, k1, 0x1
    sw      k1, 0(k0)
    jal     screen_reflush
    jal     scheduler
    jal     clear_int

	#clear interrupt and finish
clear_int:
	li		a0, TIMER_INTERVAL
	jal		reset_timer
	RESTORE_CONTEXT(USER)
	mfc0	k0, CP0_CAUSE
	li		k1, 0xffff00ff
	and		k1, k1, k0
	mtc0	k1, CP0_CAUSE
	j		exception_over
END(handle_int)

NESTED(handle_syscall, 0, sp)
    # system call handler
	SAVE_CONTEXT(USER)

	add   	a3, a2, $0
  	add   	a2, a1, $0
  	add   	a1, a0, $0
  	add  	a0, v0, $0
	jal		system_call_helper

	RESTORE_CONTEXT(USER)

	mfc0	k0, CP0_CAUSE
	li		k1, 0xffff00ff
	and		k0, k0, k1
	mtc0	k0, CP0_CAUSE
	j		exception_over
END(handle_syscall)

NESTED(handle_others, 0, sp)
    # other exception handler
	j		exception_over
END(handle_others)

LEAF(set_cp0_status)
	mtc0	a0, CP0_STATUS
	jr		ra
END(set_cp0_status)

LEAF(get_cp0_status)
  	mfc0 	v0, CP0_STATUS
  	jr   	ra
END(get_cp0_status)

LEAF(reset_timer)
	mtc0 	$0, CP0_COUNT
	mtc0	a0, CP0_COMPARE
	jr		ra
END(reset_timer)

LEAF(close_interrupt)
	mfc0    k0, CP0_STATUS
    li      k1, ~STATUS_IE
    and	    k0, k0, k1
    mtc0    k0, CP0_STATUS
	jr		ra
END(close_interrupt)

LEAF(open_interrupt)
	mfc0    k0, CP0_STATUS
    ori     k0, k0, STATUS_IE
    mtc0    k0, CP0_STATUS
	jr		ra
END(open_interrupt)

LEAF(exception_over)
	STI
	eret
END(exception_over)

LEAF(pc_new)
	mfc0    k0, CP0_EPC
    addi    k0, k0, 0x4
    mtc0    k0, CP0_EPC
    jr      ra
END(pc_new)