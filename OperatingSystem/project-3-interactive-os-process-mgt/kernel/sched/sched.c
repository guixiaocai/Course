#include "lock.h"
#include "time.h"
#include "stdio.h"
#include "sched.h"
#include "test2.h"
#include "queue.h"
#include "screen.h"
#include "syscall.h"

pcb_t pcb[NUM_MAX_TASK];

/* current running task PCB */
pcb_t *current_running;

/* global process id */
pid_t process_id = 0;

priority_t init_priority[NUM_MAX_PRIORITY];
priority_t temp_priority[NUM_MAX_PRIORITY];

extern uint32_t time_elapsed;

extern int screen_cursor_x;
extern int screen_cursor_y;

static void check_sleeping()
{
	pcb_t *temp = sleep_queue.head;
	while(temp != NULL) // !queue_is_empty(&sleep_queue)
	{
		if(temp->deadline <= time_elapsed)
		{
			temp->status = TASK_READY;
			queue_push(&ready_queue, temp);
			temp = queue_dequeue(&sleep_queue);
		}
		else
			temp = temp->next;		
	}
}

void scheduler(void)
{
    // TODO schedule	
	check_sleeping();
    current_running->cursor_x = screen_cursor_x;
    current_running->cursor_y = screen_cursor_y;

    if(current_running != &pcb[0] && current_running->status == TASK_RUNNING)
	{
		current_running->status = TASK_READY;
        queue_push(&ready_queue,current_running);
    }
    
    while(queue_is_empty(&ready_queue)){
        open_interrupt();
        check_sleeping();//however, while scheduler, no time_irq, so no time_elapsed inc
    }
    close_interrupt();

	current_running = queue_dequeue(&ready_queue);

	if(temp_priority[current_running->pid -1] < 0)
	{
		pcb_t *temp = current_running;
		do{
			queue_push(&ready_queue, current_running);
			current_running = queue_dequeue(&ready_queue);
			if(temp_priority[current_running->pid - 1] >= 0)
				break;
		}while(current_running != temp);

		//if cannot find a task whose priority >= 0, reset priority table
		if(temp_priority[current_running->pid - 1] < 0)
		{
			do{
				queue_push(&ready_queue, current_running);
				current_running = queue_dequeue(&ready_queue);
				temp_priority[current_running->pid-1] = init_priority[current_running->pid - 1];
			}while(current_running != temp);
		}			
	}
	current_running->status = TASK_RUNNING;	
	-- temp_priority[current_running->pid -1];
	screen_reflush();
    screen_cursor_x = current_running->cursor_x;
    screen_cursor_y = current_running->cursor_y;
}

void do_sleep(uint32_t sleep_time)
{
    // TODO sleep(seconds)
	current_running->status = TASK_BLOCKED;
	current_running->deadline = time_elapsed + sleep_time;
	queue_push(&sleep_queue, current_running);
	pc_new();
	current_running->user_context.cp0_epc += 4;
	do_scheduler_without_save();
}

void do_block(queue_t *queue)
{
    // block the current_running task into the queue
	current_running->status = TASK_BLOCKED;
	queue_push(queue, current_running);
}

void do_unblock_one(queue_t *queue)
{
    // unblock the head task from the queue
	if(!queue_is_empty(queue))
	{
		pcb_t *block_task = queue_dequeue(queue);
		block_task->status = TASK_READY;
		queue_push(&ready_queue, block_task);		
	}
	else
		printk("No more blocked tasks!");
}

void do_unblock_all(queue_t *queue)
{
    // unblock all task in the queue
	while(!queue_is_empty(queue))
	{
		pcb_t *block_task = queue_dequeue(queue);
		block_task->status = TASK_READY;
		queue_push(&ready_queue, block_task);
	}
}


void pcb_new(pcb_t * pcb, struct task_info * task)
{
	//memset(pcb, 0, sizeof(pcb_t));
	pcb->pid = process_id ++;
	pcb->status = TASK_READY;
	pcb->type = task->type;
	pcb->kernel_stack_top = STACK_BASE +  process_id * STACK_SIZE;
	pcb->user_stack_top = pcb->kernel_stack_top;
	pcb->kernel_context.regs[29] = pcb->kernel_stack_top;
	pcb->kernel_context.regs[31] = task->entry_point;
	pcb->kernel_context.cp0_epc = task->entry_point;
	pcb->kernel_context.cp0_status = initial_cp0_status;

	pcb->user_context.regs[29] = pcb->user_stack_top;
	pcb->user_context.regs[31] = task->entry_point;
	pcb->user_context.cp0_epc = task->entry_point;
	pcb->user_context.cp0_status = initial_cp0_status;

	process_id ++;
	//init_priority[pcb[i].pid - 1] = INIT_PRIORITY;
	//temp_priority[pcb[i].pid - 1] = INIT_PRIORITY;
	queue_push(&ready_queue, pcb);
}

void free_proc(pcb_t * pcb)
{
	stack_push(&my_stack, pcb->kernel_stack_top);
	stack_push(&my_stack, pcb->user_stack_top);

	//queue_t * queue = 
	if(queue_exist(pcb->current_queue, pcb))
		queue_remove(pcb->current_queue, pcb);
	
	pcb->status = TASK_EXITED;
	do_unblock_all(&pcb->wait_queue);
}

void do_ps()
{
	int i, j = 0;
	printf("[PROCESS TABLE]---------------------\n");
	for(i = 0; i < NUM_MAX_TASK; i ++){
		if(pcb[i].status == TASK_RUNNING){
			printf("[%d] PID : %d STATUS : RUNNING\n", j ++, pcb[i].pid);
		}
		else if(pcb[i].status == TASK_READY){
			printf("[%d] PID : %d STATUS : READY\n", j ++, pcb[i].pid);
		}
	}
}


int do_spawn(struct task_info * task)
{
	int i, j = -1;
	for(i = 0; i < NUM_MAX_TASK; i ++){
		if(pcb[i].status == TASK_BLOCKED || pcb[i].status == TASK_EXITED){
			j = i;
			break;
		}
	}
	if(i == -1){	// no more free pcb
		printf("WARNING : PCB IS FULL!\n");
		return -1;
	}
	pcb_new(&pcb[i], task);
}

void do_kill(pid_t pid)
{
	int i, j = -1;
	pcb_t *target;
	for(i = 0; i < NUM_MAX_TASK; i ++){
		if(pcb[i].pid == pid){
			target = &pcb[i];
			j = i;
		}
	}
	if(j == 1){
		printf("Cannot find Process %d. DO_KILL failed.\n", pid);
	}
	else{
		free_proc(target);
	}
}

void do_exit(void)
{
	free_proc(current_running);
	do_scheduler();
}

void do_wait(pid_t pid)
{
	int i;
	for(i = 0; i < NUM_MAX_TASK; i ++){
		if((pcb[i].status == TASK_RUNNING || pcb[i].status == TASK_READY) && pcb[i].pid == pid){
			current_running->wait_pid = pid;
			do_block(&(pcb[i].wait_queue));
			current_running->wait_pid = NULL;
			return;
		}
	}
	printf("ERROR: Process %d does not exist.\n", pid);
	return;
}

int do_getpid()
{
    return current_running->pid;
}