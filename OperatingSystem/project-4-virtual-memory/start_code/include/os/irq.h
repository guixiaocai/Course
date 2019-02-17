#ifndef INCLUDE_INTERRUPT_H_
#define INCLUDE_INTERRUPT_H_

#include "type.h"
 
enum ExcCode
{
    /* 14, 16-22, 24-31 is reserver ExcCode */
    INT,       // 0
    MOD,       // 1
    TLBL,      // 2
    TLBS,      // 3
    ADEL,      // 4
    ADES,      // 5
    IBE,       // 6
    DBE,       // 7
    SYS,       // 8
    BP,        // 9
    RI,        // 10
    CPU,       // 11
    OV,        // 12
    TR,        // 13
    FPE = 15,  // 15
    WATCH = 23 // 23
};

#define ExcCode 0x7c

/* BEV = 0 */
// Exception Enter Vector
#define BEV0_EBASE 0x80000000
#define BEV0_OFFSET 0x180

/* BEV = 1 */
#define BEV1_EBASE 0xbfc00000
#define BEV1_OFFSET 0x380

#define TIMER_INTERVAL 150000

void interrupt_helper(uint32_t, uint32_t);

void (*exception_handler[32])();//TODO???
void (*(*exception_handler_p)[32])();

/* exception handler entery */
extern void exception_handler_entry(void);
extern void exception_handler_begin(void);
extern void exception_handler_end(void);

extern void TLBexception_handler_entry(void);
extern void TLBexception_handler_begin(void);
extern void TLBexception_handler_end(void);

extern void handle_int(void);
extern void handle_mod(void);
extern void handle_tlb(void);
extern void wrong_addr(void);
extern void handle_syscall(void);
extern void handle_other(void);

#endif