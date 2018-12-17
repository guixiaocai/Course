#include "lock.h"
#include "time.h"
#include "stdio.h"
#include "sched.h"
#include "queue.h"
#include "screen.h"

pcb_t pcb[NUM_MAX_TASK];

/* current running task PCB */
pcb_t *current_running;

/* global process id */
pid_t process_id = 1;

queue_t ready_queue;
//queue_t block_queue;
static void check_sleeping()
{
}

void scheduler(void)
{
    // TODO schedule
	if(!queue_is_empty(&ready_queue))
	{
		if(current_running->pid > 1 && current_running->status == TASK_RUNNING)
		{
			// do not switch to pcb[0]
			current_running->status = TASK_READY;
			queue_push(&ready_queue,current_running);
		}		
		//switch to new task		
		current_running = queue_dequeue(&ready_queue);
		current_running->status = TASK_RUNNING;		
	}
	else
	{
		printk("No more task!\n");
	}
	return;	
}

void do_sleep(uint32_t sleep_time)
{
    // TODO sleep(seconds)
}

void do_block(queue_t *queue)
{
    // block the current_running task into the queue
	current_running->status = TASK_BLOCKED;
	queue_push(queue, current_running);
	do_scheduler();
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
