#include "irq.h"
#include "time.h"
#include "sched.h"
#include "string.h"
#include "regs.h"

static void irq_timer()
{
    // TODO clock interrupt handler.
    // scheduler, time counter in here to do, emmmmmm maybe.
   /* time_elapsed ++;
    screen_reflush();
    if(current_running->type == USER_THREAD)
    {
        close_interrupt();
        queue_push(&ready_queue, current_running);
        current_running->status = TASK_READY;
        do_scheduler();
    }
    queue_push(&ready_queue, current_running);
    current_running->status = TASK_READY;
    do_scheduler();*/
}

void other_exception_handler()
{
    // TODO other exception handler
}

void interrupt_helper(uint32_t status, uint32_t cause)
{
    // TODO interrupt handler.
    // Leve3 exception Handler.
    // read CP0 register to analyze the type of interrupt.
   /* if(cause & CAUSE_IPL == 0x8000)
        irq_timer(), printk("go to clock int\n");
    else
        other_exception_handler();*/
}
