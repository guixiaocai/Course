
#include "test.h"
#include "stdio.h"
#include "screen.h"
#include "syscall.h"
#include "time.h"
#include "sched.h"
#include "string.h"

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

struct task_info task1 = {"lab4_drawing_task1", (uint32_t)&lab4_drawing_task1, USER_PROCESS,1,1};
struct task_info task2 = {"rw_task1", (uint32_t)&rw_task1, USER_PROCESS,1,1};
struct task_info pressure_test_task = {"pressure_test1", (uint32_t)&pressure_test, USER_PROCESS,1,1};
struct task_info pressure_test_task2 = {"pressure_test2", (uint32_t)&pressure_test2, USER_PROCESS,1,1};

static struct task_info *test_tasks[16] = {&task1, &task2, &pressure_test_task,&pressure_test_task2};
static int num_test_tasks = 6;

void init_other_tasks(int task_num, struct task_info **tasks_used)
{
    int i;
    for (i = 1; i <= task_num; i++)
    {
        printk("\n> [Shell] Writing pcb %d.\n", i);
        pcb[i].valid = 1;
        pcb[i].pid = new_pid();
        pcb[i].type = tasks_used[i - 1]->type;
        pcb[i].status = TASK_READY;
        pcb[i].entry = tasks_used[i - 1]->entry_point;
        pcb[i].first_run = 1;
        pcb[i].priority_level_set = tasks_used[i - 1]->priority;
        pcb[i].timeslice_set = tasks_used[i - 1]->timeslice;
        queue_push(&ready_queue, (void *)&(pcb[i]));
        check(i);
        check(&pcb[i]);
        check(pcb[i].pid);
        check(pcb[i].entry);
    }
}

#define SHELL_LINE_POSITION 15
#define SHELL_BUFFER_SIZE 40
#define SHELL_LINE_SIZE 40
#define SHELL_HISTORY 40
#define SHELL_SCREEN_HEIGHT 15
char shell_buffer[SHELL_BUFFER_SIZE];
char shell_history[SHELL_HISTORY][SHELL_LINE_SIZE];
char argc;
char argv[10][20];

int shell_history_cnt;
int shell_history_now;
int shell_inline_position;

inline void shell_drawline()
{
    int cursor_x_now = screen_cursor_x;
    int cursor_y_now = screen_cursor_y;
    sys_move_cursor(1, SHELL_LINE_POSITION);
    printf("---------------SHELL--------------- \n");
    screen_cursor_y = cursor_y_now;
    screen_cursor_x = cursor_x_now;
    return;
}
 
inline int loop_sub(int val)
{
    if(val)
    {
        val--;
        return val;
    }
    val=SHELL_HISTORY-1;
    return val;
}

inline int loop_add(int val)
{
    val++;
    if(val==SHELL_HISTORY)
        val = 0;
    return val;
}

inline void shell_clear_input()
{
    while(shell_inline_position>0)
    {
        shell_inline_position--;
        screen_write_ch('\b');
    }
}

inline void shell_fake_input(char* input)
{
    shell_inline_position=0;
    strcpy(shell_buffer, input);
    printf("%s",input);
    shell_inline_position+=strlen(shell_buffer);
}

inline void add_to_history()
{
    strcpy(shell_history[shell_history_cnt],shell_buffer);
    shell_history_cnt=loop_add(shell_history_cnt);
}

inline void get_history()
{
    shell_clear_input();
    shell_fake_input((char*)&shell_history[shell_history_now]);
    shell_history_now=loop_sub(shell_history_now);
}

inline void reset_history()//not clear all history!!!
{
    shell_history_now=shell_history_cnt;
}

inline void print_history(int num)
{
    printf("Shell History:\n");
    reset_history();
    while(num-->0)
    {
        shell_history_now=loop_sub(shell_history_now);
        printf("%d: %s",shell_history_now, shell_history[shell_history_now]);
        printf("\n");
    }
    reset_history();
}


//Shell History End

inline void shell_add_to_buffer(char ch)
{
    shell_buffer[shell_inline_position++] = ch;
}

inline void shell_update_current_line()
{
    printf("> root@OS:%s", shell_buffer);
}
 
inline void cmd_echo()
{
    int i = 1;
    while (i < argc)
    {
        printf("%s\n", argv[i++]);
    }
}

inline void cmd_clear()
{ 
    disable_interrupt();
    screen_clear_area(SHELL_LINE_POSITION, SHELL_LINE_POSITION + SHELL_SCREEN_HEIGHT);
    enable_interrupt();
    sys_move_cursor(1, SHELL_LINE_POSITION + 1);
    return;
}

inline void cmd_ps()
{
    sys_ps();
}

inline void cmd_about()
{   
}

inline void cmd_history()
{ 
}

inline void cmd_exec()
{
    if (argc == 1)
    {
        printf("No enough args for exec.\n");
        return;
    }
    int i;
    for (i = 1; i <= (argc - 1); i++)
    {
        int num = atoi(argv[i]);
        if(num<16)
        {
            printf("Exec task: %d\n", num);
            sys_spawn(test_tasks[num]);
        }
        else
        {
            printf("Exec: Task: %d does not exist!\n", num);
        }
    }
}

inline void cmd_kill()
{
    int kill_id = atoi(argv[1]);
    if (kill_id == current_running->pid)
    {
        printf("You cannot kill yourself .\n");
        return;
    }
    if (proc_exist(kill_id))
    {
        sys_kill(kill_id);
    }
    else
    {
        printf("Process does not exist.\n");
    }
    return;
}

inline void cmd_reboot()
{ 
}

inline void cmd_set1()
{
    if(argc!=2)
    {
        printf("set1: Invalid arguments. Usage: set1 [vaddr (in hex, no 0x)]\n");
        return;
    }
    uint32_t* dumpaddr=(uint32_t *)htoi(argv[1]);
    uint32_t dumpval=*dumpaddr;
    printf("set1 addr 0x%x, result: 0x%x, %d\n",dumpaddr,dumpval, dumpval);
    return;
}

inline void cmd_set2()
{
    if(argc!=3)
    {
        printf("set2: Invalid arguments.\n");
        printf("Usage: set2 [vaddr (in hex, no 0x)] [val (in hex, no 0x)]\n");
        return;
    }
    uint32_t* setaddr=(uint32_t *)htoi(argv[1]);
    uint32_t setval=htoi(argv[2]);
    printf("set2 addr 0x%x to: 0x%x, %d\n",setaddr ,setval, setval);
    *(setaddr)=setval;
    return;
}

inline void cmd_test()
{
    unsigned int i=0;
    for(i=0xa0000000;i<0xa1f00000;i+=4)
    {
        if(*(int*)i==0x4321)
        {
            printf("%x\n",i);
        }
    }
    return ;
}

inline void cmd_start()
{
    if(argc!=2)
    {
        printf("Usage: start [proc name]\n");
        return;
    }
    int i;
    for(i=0;i<NUM_MAX_TASK;i++)
    {
        if((test_tasks[i])&&(!strcmp(test_tasks[i]->name,argv[1])))
        {
            sys_spawn(test_tasks[i]);
            return;
        }
    }
    printf("Failed to start %s.\n");
}


inline void shell_interpret_cmd()
{
    argc = 0;
    int i = 0;
    int j = 0;
    int in_space = 1;
    while (1)
    {
        if ((shell_buffer[i] == ' ') || (shell_buffer[i] == '\t') || (shell_buffer[i] == '\0'))
        {
            if (!in_space)
            {
                argv[argc++][j] = '\0';
                j = 0;
            }
            in_space = 1;
            if ((shell_buffer[i] == '\0'))
            {
                argv[argc][j] = '\0';
                break;
            }
        }
        else
        {
            in_space = 0;
            argv[argc][j++] = shell_buffer[i];
        }
        i++;
    } 
 

    if (!strcmp(argv[0], "echo"))
    {
        cmd_echo();
        return;
    }
    if (!strcmp(argv[0], "ps"))
    {
        cmd_ps();
        return;
    }
    if (!strcmp(argv[0], "clear"))
    {
        cmd_clear();
        return;
    }
    if (!strcmp(argv[0], "cls"))
    {
        cmd_clear();
        return;
    } 
    if (!strcmp(argv[0], "exec"))
    {
        cmd_exec();
        return;
    }
    if (!strcmp(argv[0], "kill"))
    {
        cmd_kill();
        return;
    }  
    if (!strcmp(argv[0], "set1"))
    {
        cmd_set1();
        return;
    }
    if (!strcmp(argv[0], "set2"))
    {
        cmd_set2();
        return;
    }
    if (!strcmp(argv[0], "test"))
    {
        cmd_test();
        return;
    }
    if (!strcmp(argv[0], "start"))
    {
        cmd_start();
        return;
    }
    if (argc != 0)
        printsys("Can not interpret command: %s, argc: %d\n", argv[0], argc);
    else
        1;
}

inline void shell_newline()
{
    printf("> root@OS> ");
}
 
 

void start_deamon(char* name)
{
    int i;
    for(i=0;i<NUM_MAX_TASK;i++)
    {
        if((test_tasks[i])&&(!strcmp(test_tasks[i]->name,name)))
        {
            sys_spawn(test_tasks[i]);
            return;
        }
    }
}

// Shell itself
void test_shell()
{
    disable_interrupt();
    enable_interrupt();
    cmd_clear();
    shell_drawline();
    sys_move_cursor(1, SHELL_LINE_POSITION + 1);
    start_deamon("vm_deamon");
    shell_newline();


    while (1)
    {
        disable_interrupt();
        char ch = read_uart_ch();
        enable_interrupt();
        if (!ch)
            continue;
        if(ch==65)//up arrow
        {
            get_history();
        }
        else if (ch == 127)//in qemu sim
        {
            if(shell_inline_position>0)
            {
                shell_inline_position--;
                screen_write_ch('\b');
            }
        }
        else if (ch == 8)//on board
        {
            if(shell_inline_position>0)
            {
                shell_inline_position--;
                screen_write_ch('\b');
            }
        }
        else if (ch != 13) //
        {
            shell_add_to_buffer(ch);
            screen_write_ch(ch);
        }
        else //ch==13
        {
            disable_interrupt();
            shell_add_to_buffer('\0');
            screen_write_ch('\n');
            shell_inline_position = 0;
            enable_interrupt();
            add_to_history();
            reset_history();
            shell_interpret_cmd();

            disable_interrupt();
            screen_reflush();
            enable_interrupt();

            shell_newline();
        }
        shell_drawline();
    }
}