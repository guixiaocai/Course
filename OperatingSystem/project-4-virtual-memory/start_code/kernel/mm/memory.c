#include "sched.h"
#include "mm.h"
#include "stdio.h"
#include "sync.h"
#include "string.h"
#include "syscall.h"

static semaphore_t swap_sleep_sem;
static mutex_lock_t swap_lock;

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

// TLB related functions //-----------------------------------------

void tlb_info()
{
    int ehi = get_CP0_ENTRYHI();
    int baddr = get_CP0_BADVADDR();
    return;
}

static int get_L2_to_swap_out()
{
    int L2_to_swap_out = -1;
    int min_swap_find = 1000;
    int l;
    for (l = 0; l < 2048; l++)
    {
        if (current_running->pte_L1p[l].inmem)
        {
            int swap_cnt = current_running->pte_L1p[l].swap_cnt;
            if (swap_cnt < min_swap_find)
            {
                min_swap_find = swap_cnt;
                L2_to_swap_out = l;
            }
        }
    }
}

uint32_t do_L2_swap(pte_L1 *pte_L1p)
//return empty/swap_in addr for new L2 page table
{
    vt100_move_cursor(1, 7); 
    int L2_to_swap_out=get_L2_to_swap_out();
    
    //check
    if (L2_to_swap_out == -1)
        panic("L2_to_swap_out==-1");

    //alloc disk
    uint32_t disk_addr;
    if (current_running->pte_L1p[L2_to_swap_out].disk_addr == 0)
    {
        disk_addr = alloc_disk(8);
        current_running->pte_L1p[L2_to_swap_out].disk_addr = disk_addr;
    }
    else
    {
        disk_addr = current_running->pte_L1p[L2_to_swap_out].disk_addr;
    }
    //write

    vt100_move_cursor(1,1);
    other_check(disk_addr);

    //8*512=4K
    int i;
    for (i = 0; i < 8; i++)
    {
        printk("sdwrite:%x, %x, %x\n",((uint32_t)current_running->pte_L1p[L2_to_swap_out].addr + 512 * i), disk_addr + 512 * i, 512);
        sdwrite(((uint32_t)current_running->pte_L1p[L2_to_swap_out].addr + 512 * i), disk_addr + 512 * i, 512);
    }

    set_breakpoint();

    current_running->pte_L1p[L2_to_swap_out].inmem = 0;
    current_running->pte_L1p[L2_to_swap_out].swap_cnt++;

    if (pte_L1p == 0)
    {
        return (uint32_t)(current_running->pte_L1p[L2_to_swap_out].addr);
    }
    else
    {
        int k;
        for (k = 0; k < 8; k++)
        {
            sdread((uint32_t)((current_running->pte_L1p[L2_to_swap_out].addr)), pte_L1p->disk_addr + 512 * i, 512);
        }
        pte_L1p->inmem = 1;
        pte_L1p->addr = (current_running->pte_L1p[L2_to_swap_out].addr);
        return (uint32_t)current_running->pte_L1p[L2_to_swap_out].addr;
    }
}

void* do_swap(pte_L2* swapin)
{
    // TODO
    // Choose a page to write to disk.
    other_check(current_running->pid);
    other_check(get_CP0_BADVADDR());

    int swap_target = clock_findnext();
    pte_L2* pte_L2p= (pte_L2*)(current_running->pte_L2p);
    if (!(pte_L2p)[swap_target].inmem)
    {
        //no page of this L2 is in mem
        panic("Need alloc other proc's mem.");
    }
 
    pte_L2p[swap_target].inmem = 0;

    uint32_t vaddr=get_CP0_BADVADDR();
    {
        uint32_t ehi = vaddr >> 13;
        ehi = ehi << 13;
        ehi |= (current_running->pid & 0xff);
        do_tlbp();
        uint32_t index = get_CP0_INDEX();
        if (index >= 64) //index[31]=1;
        {
            //do nothing
        }
        else
        {
            uint32_t elo0, elo1;
            elo0 = ((int)pte_L2p[swap_target].raddr) >> 6;//in fact this is useless
            elo1 = ((int)pte_L2p[swap_target].raddr + PAGE_SIZE) >> 6;//in fact this is useless
            elo0 |= (2 << 3) | (1 << 2) | (0 << 1) | (0);
            elo1 |= (2 << 3) | (1 << 2) | (0 << 1) | (0);
            update_tlb(ehi, elo0, elo1, index); //
        }
    }
    // Add this page to write list, and get disk_addr.
    current_running->swap_request.valid = 1;
    current_running->swap_request.size = 16;
    current_running->swap_request.mem_addr = pte_L2p[swap_target].raddr;

    //

    if(!swapin)//just alloc new page
    {
        // panic("invalid swap in");
        current_running->swap_request.disk_addr = alloc_disk(16);
        pte_L2p[swap_target].disk_addr=current_running->swap_request.disk_addr;
        sys_semaphore_down(&swap_sleep_sem);
        return pte_L2p[swap_target].raddr;
    }
    else//swap in and swap out
    {
    if (swapin->disk_addr != 0)
    {
        current_running->swap_request.disk_addr = swapin->disk_addr;
    }
    else
    {
        current_running->swap_request.disk_addr = alloc_disk(16);
    }
    swapin->raddr=pte_L2p[swap_target].raddr;
    swapin->inmem=1;
    pte_L2p[swap_target].disk_addr=current_running->swap_request.disk_addr;
    // block and wait for another proc. (use wait signal)
    sys_semaphore_down(&swap_sleep_sem);
    return swapin->raddr;

    }
}

void do_TLB_Refill()
{ 
    int vaddr = get_CP0_BADVADDR();
    int ehi = get_CP0_BADVADDR();
    ehi = ehi >> 13;
    ehi = ehi << 13;
    ehi |= (current_running->pid & 0xff);
    do_tlbp();
    unsigned int tlb_index = get_CP0_INDEX();
    int l1_index = (vaddr & 0xffe00000) >> 21;
    int l2_index = (vaddr & 0x001fe000) >> 13;
    // vt100_move_cursor(1,9);
    if (tlb_index >= 64) //INDEX 31 = 1
    {
        //Now use FIFO
        tlb_index = (tlb_clock++) % 32; //It seems that the last 32 terms in tlb works differently on borad and on qemu.
        //TODO choose tlb index
    }

    if (!current_running->pte_L1p[l1_index].setuped)
    //l2 page table has not been setuped.
    {
        pte_L2 *L2_addr = 0;
        if (!(current_running->pte_L2_count < MAX_L2_PER_PROC))
        // L2 page table switch
        {
            L2_addr = (pte_L2 *)do_L2_swap(0);
            // panic("L2 page table need switch (not setuped)");
            //TODO
        }

        {
            //build new L2 page table
            int L2_inmem_num = current_running->pte_L2_clock % 4;
            current_running->pte_L2_clock++;
            current_running->pte_L2_count++;
            if (L2_addr == 0)
            {
                L2_addr = (pte_L2 *)&((current_running->pte_L2p)[L2_inmem_num]);
            }

            int i = 0;
            for (i = 0; i++; i < 256)
            {
                L2_addr[i].setuped = 0;
                L2_addr[i].inmem = 0;
                L2_addr[i].disk_addr = 0;
                L2_addr[i].swap_cnt = 0;
            }

            // link new L2 page table to L1
            current_running->pte_L1p[l1_index].setuped = 1;
            current_running->pte_L1p[l1_index].inmem = 1;
            current_running->pte_L1p[l1_index].addr = L2_addr;
            current_running->pte_L1p[l1_index].disk_addr = 0;
        }
    }

    if (!current_running->pte_L1p[l1_index].inmem)
    //l2 page table not in memory.
    {
        current_running->pte_L1p[l1_index].addr = (pte_L2 *)do_L2_swap(&current_running->pte_L1p[l1_index]);
        // panic("L2 page table need switch (not in mem)");
    }

    pte_L2 *l2 = current_running->pte_L1p[l1_index].addr;
    if (l2[l2_index].setuped)
    {
        if (l2[l2_index].inmem) //valid
        {
            //just continue
        }
        else //not in mem
        {
            //TODO PAGE SWITCH
            panic("Page is not in memory.");
            l2[l2_index].raddr=do_swap(&l2[l2_index]); //TODO: swap in
            l2[l2_index].inmem = 1;
        }
    }
    else //this l2 vaddr first used.
    {
        void *raddr;
        //alloc_page() return 0 if failed
        if(!(raddr = alloc_page())) //alloc_page failed
        {
            raddr = do_swap(0); //TODO: swap out
            // panic("do_swap (L2 fst use)");
        }
        (l2[l2_index]).setuped = 1;
        (l2[l2_index]).inmem = 1;
        (l2[l2_index]).raddr = (void *)raddr;
        (l2[l2_index]).disk_addr = 0;
    }
    uint32_t elo0, elo1;
    elo0 = ((int)l2[l2_index].raddr) >> 6;
    elo1 = ((int)l2[l2_index].raddr + PAGE_SIZE) >> 6;
    elo0 |= (2 << 3) | (1 << 2) | (1 << 1) | (0);
    elo1 |= (2 << 3) | (1 << 2) | (1 << 1) | (0);
    update_tlb(ehi, elo0, elo1, tlb_index); //TODO
    return;
}

void mod_helper(void)
{
    panic("VADDR ILLEGAL MOD");
}

void tlb_helper(void)
{
    do_TLB_Refill();
}

// Page Alloc Operations //--------------------------------
void *init_page_stack()
{
    int addr_now = MEM_UPPER_BOUND;
    while (addr_now > MEM_BASE)
    {
        addr_now -= PAGE_SIZE << 1;
        free_page((void *)addr_now);
    }
}

void *alloc_page()
{
    if (free_mem_page_stack_point)
    {
        return free_mem_page[--free_mem_page_stack_point];
    }
    else //no free mem_page remains
    {
        return 0;
    }
}

void *free_page(void *paddr)
{
    free_mem_page[free_mem_page_stack_point++] = paddr;
}

// VM deamon proc //----------------------------------

void deamon_vm(void)
{
    //Init
    sys_semaphore_init(&swap_sleep_sem, 0);
    //sth went wrong!!! TODO
    while (1)
    {
        int h;
        if (swap_sleep_sem.queue.head) //not empty
        {
            //do swap
            set_breakpoint();
            swap_request_t *request = &((pcb_t *)swap_sleep_sem.queue.head)->swap_request; //todo
            // void	sdread(unsigned	char	*buf,	unsigned	int	base,	int	n)
            // void sdwrite(unsigned	int	base,	int	n,	unsigned	char	*buf)
            if (!request->valid)
                panic("Invalid swap operation.");
            int i;
            for (i = 0; i < request->size; i++)
            {
                printk("sdread:%x, %x, %x\n",&swap_buffer, request->disk_addr + 512 * i, 512);
                //sdread
                // disable_interrupt();
                // Have problem
                sdread(&swap_buffer, request->disk_addr + 512 * i, 512);
                // ((void (*) (void*,int,int))(0x8007b1cc))(&swap_buffer, request->disk_addr + 512 * i, 512);
                // enable_interrupt();
                sdwrite((uint32_t)request->mem_addr + 512 * i, request->disk_addr + 512 * i, 512);
                memcpy((void *)((uint32_t)request->mem_addr + 512 * i), (void *)&swap_buffer, 512);
            }
            request->valid = 0;
            sys_semaphore_up(&swap_sleep_sem);
        }
    }
}

// Disk Regulation //-------------------------------

int disk_init()
{
    disk_addr=SWAP_BASE;
}

int alloc_disk(int sectors)
{
    int tmp = disk_addr;
    disk_addr += sectors * 512;
    return tmp;
}

void do_TLB_init()
{
    int i;
    for (i = 0; i < 32; i++)
    {
        // update_tlb(0x00000001+2*i*0x1000,0x40000+2*i*0x1000+0x16,0x40000+2*i*0x1000+0x1000+0x16,i);
    }
}

// Clock Algorithm //--------------------------------

// #define CLOCK_SIZE 256*4
// int clock_point[16];
// #define next_clock(clock) ((clock==CLOCK_SIZE)?0:clock++)

int next_clock(int clock)
{
    clock++;
    if(clock==CLOCK_SIZE)return 0;
    return clock;
}

int clock_findnext()
{
    // @notused param L2start The base addr of L2 page table for current proc
    pte_L2 *L2start = (pte_L2 *)current_running->pte_L2p;
    current_running->clock_point;
    int dbg_cnt = 0;
    while (dbg_cnt++ < (3*CLOCK_SIZE))
    {
        pte_L2 *p = &L2start[current_running->clock_point];
        if (p->setuped)
        {
            if (p->inmem)
            {
                if (p->R)
                {
                    p->R = 0;
                }
                else //!p->R
                {
                    //find result
                    p->R = 1;
                    return current_running->clock_point;
                }
            }
            else //not in mem
            {
                //just skip
            }
        }
        else //not setuped
        {
        }
        current_running->clock_point = next_clock(current_running->clock_point);
    }
    panic("Clock Algorithm Failure");
}

// For Debug //-------------------------------
void wrong_addr()
{
    int baddr = get_CP0_BADVADDR();
    int epc = get_CP0_EPC();
    vt100_move_cursor(1, 3);
    printk("[Wrong Addr]: BADADDR:%x\n", (baddr));
    printk("[Wrong Addr]: EPC:%x\n", (epc));
    // current_running->user_context.cp0_epc+=4;
    while (1)
        ;
    return;
}