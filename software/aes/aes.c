
#include "fame_lib.h"
#include "FAME.h"
#include "aes.h"
#include "bs.h"
#include "key_sched.h"


#ifdef COMPACT
#include "aesround-compact.c"
#define aesround round_compact
#define aeslastround lastround_compact
#elif defined(UNROLLED)
#include "aesround-unrolled.c"
void round_unrolled (/*inputs*/ DATATYPE plain__[128],DATATYPE key__[128], /*outputs*/ DATATYPE cipher__[128]);
void lastround_unrolled (/*inputs*/ DATATYPE plain__[128],DATATYPE key__[128], /*outputs*/ DATATYPE cipher__[128]);
#define aesround round_unrolled
#define aeslastround lastround_unrolled
#elif defined(FULLY_UNROLLED)
#include "aes-inlined-unrolled.c"
#else
#error You need to define either COMPACT or UNROLLED
#endif

int fault = 0;
int ten  = 10;

// Only used on x86
#define swap_endianess(x) ((((x)>>24)&0xff)    | (((x)>>8)&0xff00) |    \
                           (((x)<<8)&0xff0000) | ((x) << 24))

// Runs FTCHK, with the current IMM_FTCHK immediate
#define ftchk(x) {                              \
    DATATYPE r;                                 \
    DATATYPE x_res = x;                         \
    FTCHK(r,IMM_FTCHK,x_res);                   \
    fault |= r;                                 \
  }

// Runs FTCHK, with "2" as immediate. It means it forces its argument
// to be in complementary dual redundant format. It's just used in
// pipelined versions.
#define ftchk_2(x) {                            \
    DATATYPE r;                                 \
    DATATYPE x_res = x;                         \
    FTCHK(r,2,x_res);                           \
    fault |= r;                                 \
  }

// Only used for pipelined version: |a| contains the output of rounds
// i and i+1, while |b| contains the output of rounds i-1 and
// i. check_val makes sure that both their outputs for round i are the
// same.
#define check_val(a,b)                                              \
  for (int j = 0; j < 128; j++) {                                   \
    fault |= ((a[j] >> SHIFT) & MASK_RIGHT_loc) != (b[j] & MASK_RIGHT_loc); \
  }                                                                 \


#ifdef PIPELINED

/* The interleaving pattern of rounds i and i+1 depends on FD (Rs):

   Given two data A and B representing the output of rounds i and i+1,
   we have:

   - FD == 1

     [ _, _, _, _, A1, A2, A3, A4 ] and [ _, _, _, _, B1, B2, B3, B4 ]

     ----->

     [ B1, B2, B3, B4, A1, A2, A3, A4 ]

     There is no redundancy, so the format of the data doesn't matter
     much. We can therefore just put B in the upper half and A in the
     lower half.


   - FD == 2

    [ _, _, A1, A2, _, _, A3, A4 ] and [ _, _, B1, B2, _, _, B3, B4 ]

    ----->

    [ B1, B2, A1, A2, B3, B4, A3, A4 ]

    A1 and A2 are the complement of A3 and A4 (likewise for B1 and
    B2). We need to keep that complementarity after there
    interleaving.


   - FD == 4

    [ _, A1, _, A2, _, A3, _, A4 ] and [ _, B1, _, B2, _, B3, _, B4 ]

    ----->

    [ B1, A1, B2, A2, B3, A3, B4, A4 ]

    This time, A1, A2, A3 and A4 represent the same data (A1 == A3 ==
    ~A2 == ~A4). To keep the redundancy/complentarity, we need to
    interleave A and B as shown.
 */

#if FD == 1
#define SHIFT 16
#define MASK_RIGHT 0x0000ffff
#define MASK_LEFT  0xffff0000
#define MASK_RIGHT_END 0xffff
#elif FD == 2
#define SHIFT 8
#define MASK_RIGHT 0x00ff00ff
#define MASK_LEFT  0xff00ff00
#define MASK_RIGHT_END 0x00ff
#elif FD == 4
#define SHIFT 4
#define MASK_RIGHT 0x0f0f0f0f
#define MASK_LEFT  0xf0f0f0f0
#define MASK_RIGHT_END 0x0f0f
#endif // #if FD == 1


#undef INTERLEAVE
#undef UNINTERLEAVE
#define INTERLEAVE(a,b) ((a & MASK_RIGHT_loc) | ((b << SHIFT) & MASK_LEFT_loc))
#define UNINTERLEAVE(a) (a & MASK_RIGHT_loc)

int AES_protected(DATATYPE plain[128], DATATYPE key[11][128], DATATYPE cipher[128], unsigned char* canary) {
  asm volatile("" : "+m" (canary));
  fault = 0;
  DATATYPE prev[128];

  int MASK_RIGHT_loc = MASK_RIGHT;
  int MASK_LEFT_loc  = MASK_LEFT;
  asm volatile("" : "+r" (MASK_RIGHT_loc));
  asm volatile("" : "+r" (MASK_LEFT_loc));


  // Initialization
  for (int i = 0; i < 128; i++)
    XOR(prev[i], plain[i], key[0][i]);
  asm volatile("" : "+m" (prev) ::);
  for (int i = 0; i < 128; i++)
    XOR(plain[i], plain[i], key[0][i]);
  asm volatile("" : "+m" (plain) ::);
  for (int i = 0; i < 128; i++)
    ftchk_2((plain[i] & 0xffff) | (prev[i] << 16));

  // first round (to get the pipeline started)
  int seed_val = get_seed();
  aesround(plain,key[1],plain);
  for (int i = 0; i < 128; i++)
    plain[i] = INTERLEAVE(plain[i], prev[i]);

  seed_prev(seed_val);

  int i = 0b00010001;
  DATATYPE roundK[128];
  DATATYPE* proundK = roundK;
  while (1) {
  start:;
    int iVal = i & 0xf;

    // computing the key
    asm volatile("": "+m" (proundK));
    proundK = roundK;
    asm volatile("": "+m" (proundK));
    for (int j = 0; j < 128; j++)
      proundK[j] = INTERLEAVE(key[iVal+1][j], key[iVal][j]);

    // storing previous result & computing new round
    fame_memcpy(prev,plain,128*4);
    aesround(plain,proundK,plain);

    // checking that the high bits of prev are the same as the low of plain
    check_val(plain,prev);

    // incrementing counter
    i += 0b00010001;
    if ((i & 0xf) != (i >> 4)) {
      return 1; // wrong value for i
    }

    /* break condition */
    if (i == 0b10011001) {
      asm volatile("" : "+r" (i)::);
      if (i == 0b10011001)
        break;
    }
    asm volatile("" : "+r" (i)::);

    if (i == 0b10011001) {
      asm volatile("" : "+r" (i)::);
      if (i == 0b10011001)
        break;
    }
    goto start;
  }
  asm volatile("" : "+r" (i)::);
  if (i != 0b10011001)
    // Exited too early
    return 1;

  // last round
  seed_val = get_seed();
  seed_prev(seed_val);
  fame_memcpy(prev,plain,128*4);
  aeslastround(plain,key[10],cipher);
  asm volatile ( "" : "+m" (key), "+r" (ten) );
  seed_prev(seed_val);
  seed(seed_val);
  aeslastround(prev,key[ten],prev);
  for (int i = 0; i < 128; i++)
    cipher[i] = UNINTERLEAVE(cipher[i]);
  for (int i = 0; i < 128; i++)
    prev[i] = UNINTERLEAVE(prev[i]);
  for (int i = 0; i < 128; i++)
    fault |= cipher[i] != prev[i];

  int expected_mask_right = MASK_RIGHT;
  asm volatile ( "" : "+r" (expected_mask_right));
  expected_mask_right |= MASK_RIGHT_END;
  asm volatile( "" : "+r" (expected_mask_right));
  fault |= expected_mask_right != MASK_RIGHT_loc;

  return fault;
}

#else // ifdef PIPELINED
 
#ifdef FULLY_UNROLLED
int AES_unprotected(DATATYPE plain[128], DATATYPE key[11][128], DATATYPE cipher[128]) {
  full_aes(plain,key,cipher);
  return 0;
}
#else
int AES_unprotected(DATATYPE plain[128], DATATYPE key[11][128], DATATYPE cipher[128]) {
  for (int i = 0; i < 128; i++)
    XOR(plain[i], plain[i], key[0][i]);
  for (int i = 1; i < 10; i++)
    aesround(plain,key[i],plain);
  aeslastround(plain,key[10],cipher);
#if FD > 1
#ifdef CORRECT
  for (int i = 0; i < 128; i++) {
    DATATYPE t = cipher[i];
    FTCHK(t, IMM_FTCHK, t);
    cipher[i] = t;
  }
#else
  for (int i = 0; i < 128; i++)
    ftchk(cipher[i]);
#endif // #ifdef CORRECT
#endif // #if FD > 1
  return 0;
}
#endif
#endif // ifdef(PIPELINED)

int check_canary(unsigned char* canary) {
  return canary[0] != 0xff;
}

int AES_wrapper(DATATYPE* plain, DATATYPE key[11][128], DATATYPE* cipher) {
  DATATYPE input[128], output[128];

#ifndef X86
  for (int i = 0; i < 128/FD/TI; i++) plain[i] = swap_endianess(plain[i]);
#endif

  // Add FD and TI, and bitslice
  normal_to_bs(plain,input);

  // Encrypt
#ifdef PIPELINED
  unsigned char canary[10];
  for (int i = 0; i < 10; i++)
    canary[i] = 0xff;
  int res = AES_protected(input,key,output,canary);
  res |= check_canary(canary);
#else
  int res = AES_unprotected(input,key,output);
#endif

  // Remove FD and TI, and un-bitslice
  bs_to_normal(output,cipher);
#ifdef X86
  for (int i = 0; i < 128/FD/TI; i++) cipher[i] = swap_endianess(cipher[i]);
#endif
  return res;
}


// length should be a multiple of 16 * (32 / FD / TI)
//    (just for convenience; should be fixed)
int AES_encrypt_data(unsigned char* input, unsigned char char_key[16],
                     unsigned char* output, unsigned int length) {
  /* Key schedule stuffs */
  unsigned char char_key_sched[176];
  key_sched(char_key,char_key_sched);
  DATATYPE key_normal[11][128];
  DATATYPE key_bs[11][128];
  for (int i = 0; i < 11; i++) {
    for (int j = 0; j < 32; j++)
      fame_memcpy(&key_normal[i][j*4],&char_key_sched[16*i],16);
#ifndef X86
    for (int j = 0; j < 128; j++) key_normal[i][j] = swap_endianess(key_normal[i][j]);
#endif
    normal_to_bs(key_normal[i], key_bs[i]);
  }
  /* Not-(key schedule) stuffs */
  // block_size : represents how many data we encrypt in parallel
  //           (for instance, for TI=FD=1, 32 data, and for TI=FD=4, 2 data)
  int block_size = 16 * 32 / FD / TI;
#ifdef PIPELINED
  block_size /= 2;
#endif
  int res = 0;
  for (unsigned int i = 0; i < length; i += block_size) {
#ifdef PIPELINED
    DATATYPE padded_input[128] = { 0 };
    DATATYPE padded_output[128];
    fame_memcpy(padded_input,&input[i],block_size);
    res |= AES_wrapper(padded_input,key_bs,padded_output);
    fame_memcpy(&output[i],padded_output,block_size);
#else
    res |= AES_wrapper((DATATYPE*)&input[i],key_bs,(DATATYPE*)&output[i]);
#endif
  }
  return res;
}
