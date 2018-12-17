#include "lock.h"
#include "sync.h"
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

int sys_spawn(struct task_info * task)
{
    invoke_syscall(SYSCALL_SPAWN, (int)task, IGNORE, IGNORE);
}

int sys_kill(pid_t pid)
{
    invoke_syscall(SYSCALL_KILL, (int)pid, IGNORE, IGNORE);
}

int sys_exit()
{
    invoke_syscall(SYSCALL_EXIT, IGNORE, IGNORE, IGNORE);
}

int sys_wait(pid_t pid)
{
    invoke_syscall(SYSCALL_WAIT, (int)pid, IGNORE, IGNORE);
}
int sys_semaphore_init(semaphore_t *s, int val)
{
    invoke_syscall(SYSCALL_SEMAPHORE_INIT, (int)s, (int)val, IGNORE);
}

int sys_semaphore_up(semaphore_t *s)
{
    invoke_syscall(SYSCALL_SEMAPHORE_UP, (int)s, IGNORE, IGNORE);
}

int sys_semaphore_down(semaphore_t *s)
{
    invoke_syscall(SYSCALL_SEMAPHORE_DOWN, (int)s, IGNORE, IGNORE);
}

int sys_condition_init(condition_t *condition)
{
    invoke_syscall(SYSCALL_CONDITION_INIT, (int)condition, IGNORE, IGNORE);
}

int sys_condition_wait(mutex_lock_t *lock, condition_t *condition)
{
    invoke_syscall(SYSCALL_CONDITION_WAIT, (int)lock, (int)condition, IGNORE);
}

int sys_condition_signal(condition_t *condition)
{
    invoke_syscall(SYSCALL_CONDITION_SIGNAL, (int)condition, IGNORE, IGNORE);
}

int sys_condition_broadcast(condition_t *condition)
{
    invoke_syscall(SYSCALL_CONDITION_BROADCAST, (int)condition, IGNORE, IGNORE);
}

int sys_barrier_init(barrier_t *barrier, int goal)
{
    invoke_syscall(SYSCALL_BARRIER_INIT, (int)barrier, (int)goal, IGNORE);
}

int sys_barrier_wait(barrier_t *barrier)
{
    invoke_syscall(SYSCALL_BARRIER_WAIT, (int)barrier, IGNORE, IGNORE);
}

int sys_ps()
{
    invoke_syscall(SYSCALL_PS, IGNORE, IGNORE, IGNORE);
}

int sys_getpid()
{
    invoke_syscall(SYSCALL_GETPID, IGNORE, IGNORE, IGNORE);
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
