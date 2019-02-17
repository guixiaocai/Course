#include "stdarg.h"
#include "screen.h"
#include "syscall.h"
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

static char mread_uart_ch(void)
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

void scanf(const char *fmt, ...)
{ 
}

void gethex(int *mem)
{ 
    char buffer[100];
    int inline_position=0;

    disable_interrupt();
    vt100_move_cursor(1,1);
    printk("                                            ");
    vt100_move_cursor(1,1);
    printk("gethex:");
    while (1)
    {
        char ch = mread_uart_ch();
        if (!ch)
            continue;

        if (ch == 127) //in qemu sim
        {
            if (inline_position > 0)
            {
                inline_position--;
                printk("\b");
            }
        }
        else if (ch == 8) //on board
        {
            if (inline_position > 0)
            {
                inline_position--;
                printk("\b");
            }
        }
        else if (ch != 13) //
        {
            buffer[inline_position++]=ch;
            printk("%c",ch);
        }
        else //ch==13
        {
            buffer[inline_position++]='\0';
            break;
        }
    }

    *mem=htoi(buffer);
    enable_interrupt();
    return;
}