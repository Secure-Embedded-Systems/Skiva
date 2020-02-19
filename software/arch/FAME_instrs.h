#pragma once

/* Defines the macros ANDC8, XORC8, XNORC8, ANDC16, XORC16, XNORC16,
   TIBS, INVTIBS, RED, FTCHK, SUBROT_2 and SUBROT_4.

 */

#if defined(X86) || defined(NO_CUSTOM_INSTR)

// load advanced custom instructions
#include "custom_instrs_soft.h"

// define ANDCx, XORCx, XNORCx
#ifdef ASM_SOFT
#define ANDC8(r,a,b) {                                          \
    DATATYPE tmp;                                               \
    DATATYPE lmask = 0xFF00FF00, rmask = 0x00FF00FF;            \
    asm volatile("or  %[a_], %[b_], %[r_]\n\t"                  \
                 "and %[r_], %[lmask_], %[r_]\n\t"              \
                 "and %[a_], %[b_], %[tmp_]\n\t"                \
                 "and %[tmp_], %[rmask_], %[tmp_]\n\t"          \
                 "or  %[r_], %[tmp_], %[r_]"                    \
                 : [r_] "=&r" (r), [tmp_] "=r" (tmp)            \
                 : [a_] "r" (a), [b_] "r" (b),                  \
                   [lmask_] "r" (lmask), [rmask_] "r" (rmask)); \
  }
#define XORC8(r,a,b) {                                                  \
    DATATYPE mask = 0xFF00FF00;                                         \
    asm volatile("xor %[a_], %[mask_], %[r_]\n\t"                       \
                 "xor %[b_], %[r_], %[r_]"                              \
                 : [r_] "=&r" (r)                                       \
                 : [a_] "r" (a), [b_] "r" (b), [mask_] "r" (mask) );    \
  }

#define ANDC16(r,a,b) {                                                 \
  DATATYPE tmp;                                                         \
  DATATYPE lmask = 0xFFFF0000, rmask = 0x0000FFFF;                      \
  asm volatile("or  %[a_], %[b_], %[r_]\n\t"                            \
               "and %[r_], %[lmask_], %[r_]\n\t"                         \
               "and %[a_], %[b_], %[tmp_]\n\t"                          \
               "and %[tmp_], %[rmask_], %[tmp_]\n\t"                     \
               "or  %[r_], %[tmp_], %[r_]"                              \
               : [r_] "=&r" (r), [tmp_] "=r" (tmp)                       \
               : [a_] "r" (a), [b_] "r" (b),                            \
                 [lmask_] "r" (lmask), [rmask_] "r" (rmask));   \
  }
#define XORC16(r,a,b) {                                                 \
    DATATYPE mask = 0xFFFF0000;                                         \
    asm volatile("xor %[a_], %[mask_], %[r_]\n\t"                       \
                 "xor %[b_], %[r_], %[r_]"                              \
                 : [r_] "=&r" (r)                                        \
                 : [a_] "r" (a), [b_] "r" (b), [mask_] "r" (mask) );    \
  }
#else
#define ANDC8(r,a,b)   r = ( ((a) | (b)) & 0xFF00FF00) | ( ((a) & (b)) & 0x00FF00FF)
#define XORC8(r,a,b)   r = (~((a) ^ (b)) & 0xFF00FF00) | ( ((a) ^ (b)) & 0x00FF00FF)
#define ANDC16(r,a,b)  r = ( ((a) | (b)) & 0xFFFF0000) | ( ((a) & (b)) & 0x0000FFFF)
#define XORC16(r,a,b)  r = (~((a) ^ (b)) & 0xFFFF0000) | ( ((a) ^ (b)) & 0x0000FFFF)
#endif // #ifdef ASM_SOFT
#define XNORC8(r,a,b)  r = ( ((a) ^ (b)) & 0xFF00FF00) | (~((a) ^ (b)) & 0x00FF00FF)
#define XNORC16(r,a,b) r = ( ((a) ^ (b)) & 0xFFFF0000) | (~((a) ^ (b)) & 0x0000FFFF)


#else // #if defined(X86) || defined(NO_CUSTOM_INSTR)

// load advanced custom instructions
#include "custom_instrs_hard.h"

// Follows: definition of XORCx, ANDCx and XNORCx when not in X86 mode.

// CHEATY_CUSTOM: not using the real custom instructions, but rather
// some normal AND/OR/XOR. Useful because on our benchmark machine,
// the custom instructions are not properly implemented and are
// therefore too slow. Using non-custom instructions allows to
// benchmark what throughput a proper implementation would produce.
#ifdef CHEATY_CUSTOM
// GCC_SUPPORT: assumes gcc knows about our custom operators. This
// allows gcc to more efficiently schedule instructions and allocate
// registers.
#ifdef GCC_SUPPORT
#define ANDC8(r,a,b)   r = (a) & (b)
#define XORC8(r,a,b)   r = (a) ^ (b)
#define ANDC16(r,a,b)  r = (a) & (b)
#define XORC16(r,a,b)  r = (a) ^ (b)
#define ANDC32(r,a,b)  r = (a) & (b)
#define XORC32(r,a,b)  r = (a) ^ (b)
#else // GCC_SUPPORT
#define ANDC8(r,a,b)   asm volatile("and %1, %2, %0\n\t"   : "=r" (r) : "r" (a), "r" (b) :)
#define XORC8(r,a,b)   asm volatile("xor %1, %2, %0\n\t"   : "=r" (r) : "r" (a), "r" (b) :)
#define XNORC8(r,a,b)  asm volatile("xnor %1, %2, %0\n\t"  : "=r" (r) : "r" (a), "r" (b) :)
#define ANDC16(r,a,b)  asm volatile("and %1, %2, %0\n\t"  : "=r" (r) : "r" (a), "r" (b) :)
#define XORC16(r,a,b)  asm volatile("xor %1, %2, %0\n\t"  : "=r" (r) : "r" (a), "r" (b) :)
#define XNORC16(r,a,b) asm volatile("xnor %1, %2, %0\n\t" : "=r" (r) : "r" (a), "r" (b) :)
#define ANDC32(r,a,b)  asm volatile("and %1, %2, %0\n\t"     : "=r" (r) : "r" (a), "r" (b) :)
#define XORC32(r,a,b)  asm volatile("xor %1, %2, %0\n\t"     : "=r" (r) : "r" (a), "r" (b) :)
#define XNORC32(r,a,b) asm volatile("xnor %1, %2, %0\n\t"    : "=r" (r) : "r" (a), "r" (b) :)
#endif // GCC_SUPPORT
#else // CHEATY_CUSTOM
#define ANDC8(r,a,b)   asm volatile("andc8 %1, %2, %0\n\t"   : "=r" (r) : "r" (a), "r" (b) :)
#define XORC8(r,a,b)   asm volatile("xorc8 %1, %2, %0\n\t"   : "=r" (r) : "r" (a), "r" (b) :)
#define XNORC8(r,a,b)  asm volatile("xnorc8 %1, %2, %0\n\t"  : "=r" (r) : "r" (a), "r" (b) :)
#define ANDC16(r,a,b)  asm volatile("andc16 %1, %2, %0\n\t"  : "=r" (r) : "r" (a), "r" (b) :)
#define XORC16(r,a,b)  asm volatile("xorc16 %1, %2, %0\n\t"  : "=r" (r) : "r" (a), "r" (b) :)
#define XNORC16(r,a,b) asm volatile("xnorc16 %1, %2, %0\n\t" : "=r" (r) : "r" (a), "r" (b) :)
#define ANDC32(r,a,b)  asm volatile("and %1, %2, %0\n\t"     : "=r" (r) : "r" (a), "r" (b) :)
#define XORC32(r,a,b)  asm volatile("xor %1, %2, %0\n\t"     : "=r" (r) : "r" (a), "r" (b) :)
#define XNORC32(r,a,b) asm volatile("xnor %1, %2, %0\n\t"    : "=r" (r) : "r" (a), "r" (b) :)
#endif // CHEATY_CUSTOM


#endif // #if defined(X86) || defined(NO_CUSTOM_INSTR)
