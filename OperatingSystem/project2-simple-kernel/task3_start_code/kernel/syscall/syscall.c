#include "lock.h"
#include "sched.h"
#include "common.h"
#include "screen.h"
#include "syscall.h"

extern int (*syscall[NUM_SYSCALLS])();

void system_call_helper(int fn, int arg1, int arg2, int arg3)
{
    // syscall[fn](arg1, arg2, arg3)
    if(fn < 0 || fn >= NUM_SYSCALLS)
        fn = 0;
    current_running->user_context.regs[2] = syscall[fn](arg1, arg2, arg3);
    if(fn != SYSCALL_BLOCK && fn != SYSCALL_SLEEP)
        current_running->user_context.cp0_epc += 4;
}

void sys_sleep(uint32_t time)
{
    invoke_syscall(SYSCALL_SLEEP, time, IGNORE, IGNORE);
}

void sys_block(queue_t *queue)
{
    invoke_syscall(SYSCALL_BLOCK, (int)queue, IGNORE, IGNORE);
}

void sys_unblock_one(queue_t *queue)
{
    invoke_syscall(SYSCALL_UNBLOCK_ONE, (int)queue, IGNORE, IGNORE);
}

void sys_unblock_all(queue_t *queue)
{
    invoke_syscall(SYSCALL_UNBLOCK_ALL, (int)queue, IGNORE, IGNORE);
}

void sys_write(char *buff)
{
    invoke_syscall(SYSCALL_WRITE, (int)buff, IGNORE, IGNORE);
}

void sys_reflush()
{
    invoke_syscall(SYSCALL_REFLUSH, IGNORE, IGNORE, IGNORE);
}

void sys_move_cursor(int x, int y)
{
    invoke_syscall(SYSCALL_CURSOR, x, y, IGNORE);
}

void mutex_lock_init(mutex_lock_t *lock)
{
    invoke_syscall(SYSCALL_MUTEX_LOCK_INIT, (int)lock, IGNORE, IGNORE);
}

void mutex_lock_acquire(mutex_lock_t *lock)
{
    invoke_syscall(SYSCALL_MUTEX_LOCK_ACQUIRE, (int)lock, IGNORE, IGNORE);
}

void mutex_lock_release(mutex_lock_t *lock)
{
    invoke_syscall(SYSCALL_MUTEX_LOCK_RELEASE, (int)lock, IGNORE, IGNORE);
}

void do_sys_sleep(uint32_t sleep_time)
{
    do_sleep(sleep_time);
}

void do_sys_other()
{
    printk("ERROR: Invalid Syscall!\n");
}

void do_sys_block(queue_t *queue)
{
    do_block(queue);
}

void do_sys_unblock_one(queue_t *queue)
{
    do_unblock_one(queue);
}

void do_sys_unblock_all(queue_t *queue)
{
    do_unblock_all(queue);
}

void do_sys_write(char *c)
{
    screen_write(c);
    screen_reflush();
}

void do_sys_move_cursor(int x, int y)
{
    screen_move_cursor(x, y);
}

void do_sys_reflush()
{
    screen_reflush(); 
}

void do_sys_mutex_lock_init(mutex_lock_t *lock)
{
    do_mutex_lock_init(lock);
}

void do_sys_mutex_lock_acquire(mutex_lock_t *lock)
{
    do_mutex_lock_acquire(lock);
}
void do_sys_mutex_lock_release(mutex_lock_t *lock)
{
    do_mutex_lock_release(lock);
}
