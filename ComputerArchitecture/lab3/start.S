#include <asm.h>
#include <regdef.h>
#include <ucas_cde.h>

#define TEST_NUM 68

#define lab2_1  1
#define lab2_2  1
#define lab2_3  1

##s0, number
##s1, number adress 
##s2, exception use
##s3, score
##s4, exception pc
	.set	noreorder
	.globl	_start
	.globl	start
	.globl	__main
_start:
start:

	b	locate
	nop

##avoid "j locate" not taken
    lui   t0, 0x8000
    addiu t1, t1, 1
    or    t2, t0, zero
    addu  t3, t5, t6
    lw    t4, 0(t0)
    nop

##avoid cpu run error
.org 0x0ec
    lui   t0, 0x8000
    addiu t1, t1, 1
    or    t2, t0, zero
    addu  t3, t5, t6
    lw    t4, 0(t0)
.org 0x100
test_finish:
    addiu t0, t0, 1
    li t1, 0xff
    LI (t2, UART_ADDR)
    sw t1, 0x0(t2)
    b test_finish
    nop
##avoid cpu run error
    lui   t0, 0x8000
    addiu t1, t1, 1
    or    t2, t0, zero
    addu  t3, t5, t6
    lw    t4, 0(t0)
/*
 *  exception handle
 */
.org 0x380

exception_handler:
    mfc0    t0, $13     ## get cp0_cause
    nop
    andi    t1, t0, 0x8000
    bgtz    t1, clock_int
    nop
    andi    t1, t0, 0x6000
    bgtz    t1, key_int
    nop

exception_is_done:
    mfc0    t0, $13
    nop
    andi    t1, t0, 0xff00
    xor     t0, t0, t1
    mtc0    t0, $13
    nop
    eret
    nop

clock_int:
    bgezal  s7, clock_int
    nop
    jal     get_time
    nop
    jal     reset_timer
    nop
    j		exception_is_done
    nop    

key_int:
    li      t1, BTN_KEY_ADDR
    lw		t0, (t1)
    andi    t0, t0, 0xf
    beqz	t0, exception_is_done
    nop
    andi    t1, t0, 0x1
    beqz    t1, 1f
    nop
    addiu   t1, $0, -1
    xor     s7, s7, t1
    mfc0    t0, $12     ## get cp0_status
    nop
    xori    t0, t0, 0x8000
    mtc0    t0, $12
    nop
    j		press_key
    nop
1:
    beqz    s7, exception_is_done
    nop
    andi    t1, t0, 0x2
    beqz    t1, 1f
    nop
    jal     add_1h
    nop
    jal     get_time
    nop
    j		press_key    
    nop
1:
    andi    t1, t0, 0x4
    beqz    t1, 1f
    nop
    jal     add_1m
    nop
    jal     get_time
    nop
    j		press_key
    nop
1:
    jal     add_1s
    nop
    jal     get_time
    nop
    j		press_key
    nop

press_key:
    li      t0, 300
1:
    addiu   t0, t0, -1
    bnez    t0, 1b
    nop
    jal     reset_timer
    nop
    j		exception_is_done
    nop

locate:
	.set noreorder
    mtc0    $0, $12
    nop
    jal     time_reset
    nop
    li      s7, 0     ## setting mode bit
    jal     get_time
    nop
    jal     reset_timer
    nop
    li      t1, 0xffff
    sw      t1, LED_ADDR($0)
    li      t0, 0x10400001
    mfc0    t1, $12
    nop
    or      t1, t1, t0
    mtc0    t1, $12
    nop
    ##
1:
	b     1b
	nop

get_time:
    ## caculate the result of time
    addu    s6, s5, $0
    sll     s6, s6, 4
    addu    s6, s4, $0
    sll     s6, s6, 4
    addu    s6, s3, $0
    sll     s6, s6, 4
    addu    s6, s2, $0
    sll     s6, s6, 4
    addu    s6, s1, $0
    sll     s6, s6, 4
    addu    s6, s0, $0
    sll     s6, s6, 4
    li      s8, NUM_ADDR
    sw      s6, (s8)
    ##sw      s6, NUM_ADDR($0)
    jr      ra
    nop
    
caculate_carry:
    li      t0, 10
    li      t1, 6
    bne		s0, t0, 1f  ## if s0 do not carry
    nop
    ## if s0 carries
    addiu   s1, s1, 1
    li      s0, 0
1:
    bne     s1, t1, 1f  ## if s1 do not carry
    nop
    ## if s1 carries
    addiu   s2, s2, 1
    li      s1, 0
1:
    bne     s2, t0, 1f  ## if s2 do not carry
    nop
    ## if s2 carries
    addiu   s3, s3, 1
    li      s2, 0
1:
    bne     s3, t1, 1f  ## if s3 do not carry
    nop
    ## if s3 carries
    addiu   s4, s4, 1
    li      s3, 0
1:
    bne     s4, t0, 1f  ## if s4 do not carry
    nop
    ## if s4 carries
    addiu   s5, s5, 1
    li      s4, 0
1:
    sll     t1, s5, 4
    addu    t1, t1, s4
    li      t0, 0x24
    beq     t0, t1, 1f  ## if s5 carries
    nop
    jr      ra
    nop
1:
    li      s4, 0
    li      s5, 0

time_reset:
    ## initialize each digit of time
    li      s0, 5   ## unit's digit of second
    li      s1, 5   ## ten's digit of second 
    li      s2, 9   ## unit's digit of minute
    li      s3, 5   ## ten's digit of minute
    li      s4, 3   ## unit's digit of hour
    li      s5, 2   ## ten's digit of hour
    jr		ra
    nop

add_1s:
    ## add 1 second
    addu    v0, ra, $0
    addiu   s0, s0, 1
    jal		caculate_carry
    nop
    addu    ra, v0, $0
    jr      ra
    nop

add_1m: 
    ## add 1 minute
    addu    v0, ra, $0
    addiu   s2, s2, 1
    jal		caculate_carry
    nop
    addu    ra, v0, $0
    jr      ra
    nop

add_1h:
    ## add 1 hour
    addu    v0, ra, $0
    addiu   s4, s4, 1
    jal		caculate_carry
    nop
    addu    ra, v0, $0
    jr      ra
    nop
    
reset_timer:
    ## reset cp0_count register
    mtc0    $0, $9
    nop
    ## reset cp0_compare register
    mtc0    t0, $11
    nop
    jr      ra
    nop



