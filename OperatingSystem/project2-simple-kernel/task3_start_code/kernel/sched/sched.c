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
pid_t process_id = 1;

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
        check_sleeping();
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
