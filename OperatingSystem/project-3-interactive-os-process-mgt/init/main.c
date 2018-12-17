/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  * * * * * * * * * * *
 *            Copyright (C) 2018 Institute of Computing Technology, CAS
 *               Author : Han Shukai (email : hanshukai@ict.ac.cn)
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  * * * * * * * * * * *
 *         The kernel's entry, where most of the initialization work is done.
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  * * * * * * * * * * *
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this 
 * software and associated documentation files (the "Software"), to deal in the Software 
 * without restriction, including without limitation the rights to use, copy, modify, 
 * merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit 
 * persons to whom the Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE. 
 * 
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  * * * * * * * * * * */

#include "irq.h"
#include "test.h"
#include "sync.h"
#include "stdio.h"
#include "sched.h"
#include "screen.h"
#include "common.h"
#include "syscall.h"

pcb_t pcb[NUM_MAX_TASK];
pcb_t *current_running;

queue_t ready_queue;
queue_t block_queue;
queue_t sleep_queue;

uint32_t initial_cp0_status;

uint32_t exception_handler[32];
extern int (*syscall[NUM_SYSCALLS])();

static void init_pcb()
{
	int i, j;
	pcb_t *p;
	queue_init(&ready_queue);
	queue_init(&block_queue);
	queue_init(&sleep_queue);
	current_running = pcb;
	initial_cp0_status = 0x10008000;
	int num_tasks = num_shell_tasks;
	struct task_info ** my_tasks = shell_tasks;
	for(i = 0; i < num_tasks; i++)
	{
		pcb_new(&pcb[i], my_tasks[i]);
	}
}

static void init_exception_handler()
{
	int i;
	for(i = 0; i < 32; i ++){
		exception_handler[i] = (uint32_t ) handle_others;
	}
	exception_handler[0] = (uint32_t ) handle_int;
	exception_handler[8] = (uint32_t ) handle_syscall;
}

static void init_exception()
{
	init_exception_handler();
	bzero(BEV1_EBASE, BEV1_OFFSET);
	memcpy((BEV1_EBASE + BEV1_OFFSET), exception_handler_entry, (exception_handler_end - exception_handler_begin));
	
	// 1. Get CP0_STATUS
	uint32_t cp0_status =  get_cp0_status();
	cp0_status |=0x8000;
	set_cp0_status(0x10000000 | cp0_status);
	
	// 2. Disable all interrupt
	close_interrupt();
	
	// 3. Copy the level 2 exception handling code to 0x80000180
	bzero(BEV0_EBASE, BEV0_OFFSET);
	memcpy((BEV0_EBASE + BEV0_OFFSET), exception_handler_entry, (exception_handler_end - exception_handler_begin));
	
	// 4. reset CP0_COMPARE & CP0_COUNT register
	reset_timer(TIMER_INTERVAL);
}

static void init_syscall(void)
{
	// init system call table.
	int i;
	for(i = 0; i < NUM_SYSCALLS; i ++)
	{
		syscall[i] = (int (*)()) do_sys_other;
	}
	syscall[SYSCALL_SLEEP] = (int (*)()) do_sys_sleep;
	syscall[SYSCALL_BLOCK] = (int (*)()) do_sys_block;
	syscall[SYSCALL_UNBLOCK_ONE] = (int (*)()) do_sys_unblock_one;
	syscall[SYSCALL_UNBLOCK_ALL] = (int (*)()) do_sys_unblock_all;
	syscall[SYSCALL_WRITE] = (int (*)()) do_sys_write;
	syscall[SYSCALL_CURSOR] = (int (*)()) do_sys_move_cursor;
	syscall[SYSCALL_REFLUSH] = (int (*)()) do_sys_reflush;
	syscall[SYSCALL_SPAWN] = (int (*)()) do_spawn;
    syscall[SYSCALL_KILL] = (int (*)()) do_kill;
    syscall[SYSCALL_EXIT] = (int (*)()) do_exit;
    syscall[SYSCALL_WAIT] = (int (*)()) do_wait;
	syscall[SYSCALL_MUTEX_LOCK_INIT] = (int (*)()) do_sys_mutex_lock_init;
	syscall[SYSCALL_MUTEX_LOCK_ACQUIRE] = (int (*)()) do_sys_mutex_lock_acquire;
	syscall[SYSCALL_MUTEX_LOCK_RELEASE] = (int (*)()) do_sys_mutex_lock_release;
	syscall[SYSCALL_SEMAPHORE_INIT] = (int (*)()) do_semaphore_init;
    syscall[SYSCALL_SEMAPHORE_UP] = (int (*)()) do_semaphore_up;
    syscall[SYSCALL_SEMAPHORE_DOWN] = (int (*)()) do_semaphore_down;
    syscall[SYSCALL_CONDITION_INIT] = (int (*)()) do_condition_init;
    syscall[SYSCALL_CONDITION_WAIT] = (int (*)()) do_condition_wait;
    syscall[SYSCALL_CONDITION_SIGNAL] = (int (*)()) do_condition_signal;
    syscall[SYSCALL_CONDITION_BROADCAST] = (int (*)()) do_condition_broadcast;
    syscall[SYSCALL_BARRIER_INIT] = (int (*)()) do_barrier_init;
    syscall[SYSCALL_BARRIER_WAIT] = (int (*)()) do_barrier_wait;
    syscall[SYSCALL_PS] = (int (*)()) do_ps;
    syscall[SYSCALL_GETPID] = (int (*)()) do_getpid;
}

// jump from bootloader.
// The beginning of everything >_< ~~~~~~~~~~~~~~
void __attribute__((section(".entry_function"))) _start(void)
{
	// Close the cache, no longer refresh the cache 
	// when making the exception vector entry copy
	asm_start();

	// init interrupt (^_^)
	time_elapsed = 0;
	init_exception();
	printk("> [INIT] Interrupt processing initialization succeeded.\n");

	// init system call table (0_0)
	init_syscall();
	printk("> [INIT] System call initialized successfully.\n");

	// init Process Control Block (-_-!)
	init_pcb();
	printk("> [INIT] PCB initialization succeeded.\n");

	// init screen (QAQ)
	init_screen();
	printk("> [INIT] SCREEN initialization succeeded.\n");

	// TODO Enable interrupt
	open_interrupt();

	while (1)
	{
		// (QAQQQQQQQQQQQ)
		// If you do non-preemptive scheduling, you need to use it to surrender control
		do_scheduler();
	};
	return;
}
