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
#include "stdio.h"
#include "sched.h"
#include "screen.h"
#include "common.h"
#include "syscall.h"

pcb_t pcb[NUM_MAX_TASK];
pcb_t *current_running;
queue_t ready_queue;
//queue_t block_queue;

static void init_pcb()
{
	int i, j;
	pcb_t *p;
	p = pcb;
	queue_init(&ready_queue);
	
	p->pid = process_id ++;
	p->type = KERNEL_THREAD;
	p->status = TASK_RUNNING;
	p->kernel_stack_top = 0xa0f00000;
	queue_push(&ready_queue, p);

	struct task_info *tasks[NUM_MAX_TASK];
	for(i = 0; i < num_sched1_tasks; i ++)
		tasks[i] = sched1_tasks[i];
	for(i = 0; i < num_lock_tasks; i ++)
		tasks[i+num_sched1_tasks] = lock_tasks[i];
		
	for(i = 0; i < num_lock_tasks + num_sched1_tasks; i++)
	{
		p ++;
		p->pid = process_id ++;
		p->status = TASK_READY;
		p->type = tasks[i]->type;
		p->kernel_stack_top = 0xa0f00000 - (i + 1) * 0x10000;
		for(j = 0; j < 32; j ++)
			p->kernel_context.regs[j] = 0;
		p->kernel_context.regs[29] = p->kernel_stack_top;
		p->kernel_context.regs[31] = tasks[i]->entry_point;
		queue_push(&ready_queue, p);
	}
	current_running = pcb;
}

static void init_exception_handler()
{
}

static void init_exception()
{
	// 1. Get CP0_STATUS
	/*CP0_STATUS = ;
	// 2. Disable all interrupt
	// 3. Copy the level 2 exception handling code to 0x80000180
	memcpy(0x80000180, *exception_handler_entry, );
	// 4. reset CP0_COMPARE & CP0_COUNT register
	CP0_COMPARE
	CP0_COUNT*/
}

static void init_syscall(void)
{
	// init system call table.
}

// jump from bootloader.
// The beginning of everything >_< ~~~~~~~~~~~~~~
void __attribute__((section(".entry_function"))) _start(void)
{
	// Close the cache, no longer refresh the cache 
	// when making the exception vector entry copy
	asm_start();

	// init interrupt (^_^)
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
	
	while (1)
	{
		// (QAQQQQQQQQQQQ)
		// If you do non-preemptive scheduling, you need to use it to surrender control
		do_scheduler();
	};
	return;
}
