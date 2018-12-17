#include "lock.h"
#include "sched.h"
#include "syscall.h"

void spin_lock_init(spin_lock_t *lock)
{
    lock->status = UNLOCKED;
}

void spin_lock_acquire(spin_lock_t *lock)
{
    while (LOCKED == lock->status)
    {
    };
    lock->status = LOCKED;
}

void spin_lock_release(spin_lock_t *lock)
{
    lock->status = UNLOCKED;
}

void do_mutex_lock_init(mutex_lock_t *lock)
{
    lock->status = UNLOCKED;
    queue_init(&lock->block_queue);
}

void do_mutex_lock_acquire(mutex_lock_t *lock)
{
    if(LOCKED == lock->status)
    {
        do_block(&lock->block_queue);
        pc_new();
        current_running->user_context.cp0_epc += 4;
        do_scheduler_without_save();
    }
    lock->status = LOCKED;

}

void do_mutex_lock_release(mutex_lock_t *lock)
{
    if(!queue_is_empty(&lock->block_queue))
        do_unblock_one(&lock->block_queue);
    else
        lock->status = UNLOCKED;
    
}
