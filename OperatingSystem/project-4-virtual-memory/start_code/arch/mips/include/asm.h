#include "regs.h"

/*
 * LEAF - declare leaf routine
 */
#define LEAF(symbol)             \
        .globl symbol;           \
        .align 2;                \
        .type symbol, @function; \
        .ent symbol, 0;          \
        symbol:                  \
        .frame sp, 0, ra

/*
 * NESTED - declare nested routine entry point
 */
#define NESTED(symbol, framesize, rpc) \
        .globl symbol;                 \
        .align 2;                      \
        .type symbol, @function;       \
        .ent symbol, 0;                \
        symbol:                        \
        .frame sp, framesize, rpc

/*
 * END - mark end of function
 */
#define END(function)  \
        .end function; \
        .size function, .- function


#define EXPORT(symbol) \
        .globl symbol; \
        symbol:
        

#define FEXPORT(symbol)          \
        .globl symbol;           \
        .type symbol, @function; \
        symbol:

