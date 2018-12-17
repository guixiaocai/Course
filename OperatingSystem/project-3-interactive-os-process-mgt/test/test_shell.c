/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  * * * * * * * * * * *
 *            Copyright (C) 2018 Institute of Computing Technology, CAS
 *               Author : Han Shukai (email : hanshukai@ict.ac.cn)
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  * * * * * * * * * * *
 *                  The shell acts as a task running in user mode. 
 *       The main function is to make system calls through the user's output.
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  * * * * * * * * * * *
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this 
 * software and associated documentation files (the "Software"), to deal in the Software 
 * without restriction, including without limitation the rights to use, copy, modify, 
 * merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit 
 * persons to whom the Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 * 
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  * * * * * * * * * * */

#include "test.h"
#include "stdio.h"
#include "screen.h"
#include "syscall.h"

static void disable_interrupt()
{
    uint32_t cp0_status = get_cp0_status();
    cp0_status &= 0xfffffffe;
    set_cp0_status(cp0_status);
}

static void enable_interrupt()
{
    uint32_t cp0_status = get_cp0_status();
    cp0_status |= 0x01;
    set_cp0_status(cp0_status);
}

static char read_uart_ch(void)
{
    char ch = 0;
    unsigned char *read_port = (unsigned char *)(0xbfe48000 + 0x00);
    unsigned char *stat_port = (unsigned char *)(0xbfe48000 + 0x05);

    while ((*stat_port & 0x01))
    {
        ch = *read_port;
    }
    return ch;
}

struct task_info task1 = {"task1", (uint32_t)&ready_to_exit_task, USER_PROCESS};
struct task_info task2 = {"task2", (uint32_t)&wait_lock_task, USER_PROCESS};
struct task_info task3 = {"task3", (uint32_t)&wait_exit_task, USER_PROCESS};

struct task_info task4 = {"task4", (uint32_t)&semaphore_add_task1, USER_PROCESS};
struct task_info task5 = {"task5", (uint32_t)&semaphore_add_task2, USER_PROCESS};
struct task_info task6 = {"task6", (uint32_t)&semaphore_add_task3, USER_PROCESS};

struct task_info task7 = {"task7", (uint32_t)&producer_task, USER_PROCESS};
struct task_info task8 = {"task8", (uint32_t)&consumer_task1, USER_PROCESS};
struct task_info task9 = {"task9", (uint32_t)&consumer_task2, USER_PROCESS};

struct task_info task10 = {"task10", (uint32_t)&barrier_task1, USER_PROCESS};
struct task_info task11 = {"task11", (uint32_t)&barrier_task2, USER_PROCESS};
struct task_info task12 = {"task12", (uint32_t)&barrier_task3, USER_PROCESS};

struct task_info task13 = {"SunQuan",(uint32_t)&SunQuan, USER_PROCESS};
struct task_info task14 = {"LiuBei", (uint32_t)&LiuBei, USER_PROCESS};
struct task_info task15 = {"CaoCao", (uint32_t)&CaoCao, USER_PROCESS};

static struct task_info *test_tasks[16] = {&task1, &task2, &task3,
                                           &task4, &task5, &task6,
                                           &task7, &task8, &task9,
                                           &task10, &task11, &task12,
                                           &task13, &task14, &task15};
static int num_test_tasks = 15;

#define SHELL_HEIGHT 15 //SHELL_SCREEN_HEIGHT
#define SHELL_WIDTH 40 //SHELL_LINE_SIZE
#define MAX_BUFFER_SIZE 40

char shell_buf[MAX_BUFFER_SIZE];
char argc;
char argv[10][20];
int shell_cursor_x; //shell_inline_position

//-------------------------------------------------------------------------------
// read the input

void do_clear_cmd()
{
    disable_interrupt();
    screen_clear(SHELL_HEIGHT, SHELL_HEIGHT * 2);
    enable_interrupt();
    sys_move_cursor(1, SHELL_HEIGHT + 1);
}

void do_ps_cmd()
{
    sys_ps();
}

void do_exec_cmd()
{
    int i, num;
    for(i = 1; i < argc; i ++){
        num = atoi(argv[i]);
        printf("exec process[%d].\n", num);
        sys_spawn(test_tasks[num]);
    }
}

void do_kill_cmd()
{
    int id = atoi(argv[1]);
    if(id == current_running->pid){
        printf("Do not kill yourself!\n");
        return;
    }
    sys_kill(id);
}

void get_cmd()
{
    int i, j;
    i = j = 0;
    int is_in_space = 1;
    argc = 0;
    while(1){
        if(shell_buf[i] != ' ' && shell_buf[i] != '\t' && shell_buf[i] != '\0'){
            is_in_space = 0;
            argv[argc][j++] = shell_buf[i];
        }
        else{
            if(is_in_space == 0){
                argv[argc++][j] = '\0';
                j = 0;
            }
            is_in_space = 1;
            if(shell_buf[i] == '\0')
                break;
        }
    }
    if(!strcmp(argv[0], "clear")){
        do_clear_cmd();
        return;
    }
    if(!strcmp(argv[0], "ps")){
        do_ps_cmd();
        return;
    }
    if(!strcmp(argv[0], "exec")){
        if(argc == 1){
            printf("Invalid exec command!\n");
            return;
        }
        do_exec_cmd();
        return;
    }
    if(!strcmp(argv[0], "kill")){
        do_kill_cmd();
        return;
    }
    if(argc){
        printf("Invalid Command!\n");
    }
}



//--------------------------------------------------------------------------------
// print something in the screen

void write_buf(char ch)
{
    shell_buf[shell_cursor_x++] = ch;
}

void print_shell_line()
{
    int temp_x = screen_cursor_x;
    int temp_y = screen_cursor_y;
    sys_move_cursor(1, SCREEN_HEIGHT);
    printf("-----------------------COMMAND----------------------Copyright (C) 2018 ZHONG Yun\n");
    screen_cursor_x = temp_x;
    screen_cursor_y = temp_y;
}



void test_shell()
{
    do_clear_cmd();
    print_shell_line();
    sys_move_cursor(1, SHELL_HEIGHT + 1);
    printf("> root@MY_OS ");
    while (1)
    {
        // read command from UART port
        disable_interrupt();
        char ch = read_uart_ch();
        enable_interrupt();

        // TODO solve command
        if(!ch) // '\0'
            continue;
        if(ch != 13){ // '\n'
            write_buf(ch);
            screen_write_ch(ch);

        }
        else{
            disable_interrupt();
            write_buf('\0');
            screen_write_ch('\n');
            shell_cursor_x = 0;
            enable_interrupt();
            get_cmd();
            disable_interrupt();
            screen_reflush();
            enable_interrupt();
            printf("> root@MY_OS ");
        }
        print_shell_line();
    }
}