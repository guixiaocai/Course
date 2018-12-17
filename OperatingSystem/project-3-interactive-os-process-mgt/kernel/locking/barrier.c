#include "barrier.h"

void do_barrier_init(barrier_t *barrier, int goal)
{
    barrier->goal = goal;
    barrier->num_waiting = 0;
    queue_init(&barrier->queue);
}

void do_barrier_wait(barrier_t *barrier)
{
    barrier->num_waiting ++;
    if(barrier->num_waiting == barrier->goal){
        do_unblock_all(&barrier->queue);
        barrier->num_waiting = 0;
    }
    else{
        do_block(&barrier->queue);
    }
}