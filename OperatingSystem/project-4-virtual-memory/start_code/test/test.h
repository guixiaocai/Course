 
#ifndef INCLUDE_TEST_H_
#define INCLUDE_TEST_H_

#include "test3.h"
#include "test4.h"
#include "sched.h"


extern struct task_info *sched1_tasks[16];
extern int num_sched1_tasks;

extern struct task_info *lock_tasks[16];
extern int num_lock_tasks;

extern struct task_info *timer_tasks[16];
extern int num_timer_tasks;

extern struct task_info *sched2_tasks[16];
extern int num_sched2_tasks;

extern struct task_info *task4_tasks[16];
extern int num_task4_tasks;

extern struct task_info *task5_tasks[16];
extern int num_task5_tasks;

extern struct task_info *shell_tasks[16];
extern int num_shell_tasks;

#endif