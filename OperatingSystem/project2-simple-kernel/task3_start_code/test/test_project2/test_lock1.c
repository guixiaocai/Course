#include "test2.h"
#include "lock.h"
#include "stdio.h"
#include "syscall.h"


static char blank[] = {"                                             "};
int is_init = 0;
/* if you want to use spin lock, you need define SPIN_LOCK */
//  #define SPIN_LOCK
spin_lock_t spin_lock;

/* if you want to use mutex lock, you need define MUTEX_LOCK */
#define MUTEX_LOCK
mutex_lock_t mutex_lock;

void lock_task1(void)
{
        //printk("is_init in lock_task1: 0x%x\n",is_init);
        //is_init = 0;
        //printk("is_init in lock_task1: 0x%x\n",is_init);
        int print_location = 3;
        while (1)
        {
                int i;
                if (!is_init)
                {

#ifdef SPIN_LOCK
                        spin_lock_init(&spin_lock);
#endif

#ifdef MUTEX_LOCK
                        do_mutex_lock_init(&mutex_lock);
#endif
                        is_init = 1;
                }

                vt100_move_cursor(1, print_location);
                printk("%s", blank);

                vt100_move_cursor(1, print_location);
                printk("> [TASK1] Applying for a lock.\n");

                do_scheduler();

#ifdef SPIN_LOCK
                spin_lock_acquire(&spin_lock);
#endif

#ifdef MUTEX_LOCK
                do_mutex_lock_acquire(&mutex_lock);
#endif

                for (i = 0; i < 20; i++)
                {
                        vt100_move_cursor(1, print_location);
                        printk("> [TASK1] Has acquired lock and running.(%d)\n", i);
                        do_scheduler();
                }

                vt100_move_cursor(1, print_location);
                printk("%s", blank);

                vt100_move_cursor(1, print_location);
                printk("> [TASK1] Has acquired lock and exited.\n");

#ifdef SPIN_LOCK
                spin_lock_release(&spin_lock);
#endif

#ifdef MUTEX_LOCK
                do_mutex_lock_release(&mutex_lock);
#endif
                do_scheduler();
        }
}

void lock_task2(void)
{
        //printk("is_init in lock_task2: 0x%x\n",is_init);
        //is_init=0;
        //printk("is_init in lock_task2: 0x%x\n",is_init);
        int print_location = 4;
        while (1)
        {
                int i;
                if (!is_init)
                {

#ifdef SPIN_LOCK
                        spin_lock_init(&spin_lock);
#endif

#ifdef MUTEX_LOCK
                        do_mutex_lock_init(&mutex_lock);
#endif
                        is_init = 1;
                }

                vt100_move_cursor(1, print_location);
                printk("%s", blank);

                vt100_move_cursor(1, print_location);
                printk("> [TASK2] Applying for a lock.\n");

                do_scheduler();

#ifdef SPIN_LOCK
                spin_lock_acquire(&spin_lock);
#endif

#ifdef MUTEX_LOCK
                do_mutex_lock_acquire(&mutex_lock);
#endif

                for (i = 0; i < 20; i++)
                {
                        vt100_move_cursor(1, print_location);
                        printk("> [TASK2] Has acquired lock and running.(%d)\n", i);
                        do_scheduler();
                }

                vt100_move_cursor(1, print_location);
                printk("%s", blank);

                vt100_move_cursor(1, print_location);
                printk("> [TASK2] Has acquired lock and exited.\n");

#ifdef SPIN_LOCK
                spin_lock_release(&spin_lock);
#endif

#ifdef MUTEX_LOCK
                do_mutex_lock_release(&mutex_lock);
#endif
                do_scheduler();
        }
}