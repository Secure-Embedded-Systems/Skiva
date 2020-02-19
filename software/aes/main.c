#include <stdio.h>

#ifdef X86
#include <x86intrin.h>
#else
#include "gptimer.h"
#endif

#include "fame_lib.h"
#include "FAME.h"

#include "aes.h"

int fault_flags = 0;

#if defined(FULLY_UNROLLED) && defined(PIPELINED)
#error Cannot be fully unrolled and pipelined
#endif

#ifndef IMPLEM_NAME
#warn No implem name
#define IMPLEM_NAME "main"
#endif


void test_AES_ref_input() {
  unsigned char key[16] = { 0 };
  unsigned char input[128*4] = { 0 };
  input[0] = 0x10; input[1] = 0xF0;
  input[16*31] = 0xa0;
  unsigned char output[128*4];
  int res = AES_encrypt_data(input,key,output,4*128);
  if (res) {
    printf("Fault detected. (didn't return 0)\n");
  }
  unsigned char out_first_expected[16] =
    { 0xb6,  0x9, 0x2b, 0xd1, 0xce, 0x83, 0xa4, 0xbc,
      0xa4, 0xb8, 0xc2, 0xac, 0x37, 0x48, 0xa1, 0x86 };
  unsigned char out_mid_expected[16] =
    { 0x66, 0xe9, 0x4b, 0xd4, 0xef, 0x8a, 0x2c, 0x3b,
      0x88, 0x4c, 0xfa, 0x59, 0xca, 0x34, 0x2b, 0x2e };
  unsigned char out_end_expected[16] =
    { 0xdd, 0x13, 0xde, 0xb8, 0xbe, 0xa4, 0xf6, 0x5f,
      0xc5, 0xcc, 0x3f, 0x7e, 0xab, 0x2a, 0x4e, 0x18 };

  int ok = 1;
  if (fault_flags) {
    ok = 0;
    printf("Fault detected (fault flags are set).\n");
  }

  if (fame_memcmp(&output[0],out_first_expected,16) != 0) {
    ok = 0;
    printf("Error first:\n  - ");
    for (int j = 0; j < 16; j++) printf("%02x",output[j]);
    printf("\n  - ");
    for (int j = 0; j < 16; j++) printf("%02x",out_first_expected[j]);
    printf("\n");
  }
  for (int i = 1; i < 31; i++)
    if (fame_memcmp(&output[i*16],out_mid_expected,16) != 0) {
      printf("Error mid:\n  - ");
      for (int j = 0; j < 16; j++) printf("%02x",output[i*16+j]);
      printf("\n  - ");
      for (int j = 0; j < 16; j++) printf("%02x",out_mid_expected[j]);
      printf("\n");
      ok = 0;
    }
  if (fame_memcmp(&output[16*31],out_end_expected,16) != 0) {
    printf("Error end:\n  - ");
    for (int j = 0; j < 16; j++) printf("%02x",output[16*31+j]);
    printf("\n  - ");
    for (int j = 0; j < 16; j++) printf("%02x",out_end_expected[j]);
    printf("\n");
    ok = 0;
  }

  if (ok)
    printf("AES seems correct.\n");

}


// Note: BUFF_SIZE should be a multiple of (16 * 32)
#define BUFF_SIZE 4096
#ifdef X86
#define NB_RUN 100
#else
#define NB_RUN 10
#endif

int waiting_cycles = 0;

void bench_full() {
  unsigned char key[16] = { 0 };
  unsigned char input[BUFF_SIZE] = { 0 };

  // Warming up caches (dunno if it's actually useful for Leon)
  for (int i = 0; i < NB_RUN; i++)
    AES_encrypt_data(input,key,input,BUFF_SIZE);

#ifdef X86
  unsigned long timer = _rdtsc();
#else
  timer_lap();
#endif

  for (int i = 0; i < NB_RUN; i++)
    AES_encrypt_data(input,key,input,BUFF_SIZE);

#ifdef X86
  timer = _rdtsc() - timer;
  printf("bench_full: %lu cycles/byte.\n",timer/BUFF_SIZE/NB_RUN);
#else
  unsigned int timer = timer_lap();
  printf("bench_full: %x /4096\n",timer);
#endif

}

#define NB_PRIMITIVE_RUN (NB_RUN * 10)

void bench_AES_primitive() {
  DATATYPE key[11][128];
  for (int i = 0; i < 11; i++)
    for (int j = 0; j < 128; j++)
      key[i][j] = 0;
  DATATYPE input[128]  = { 0 };
  DATATYPE output[128];

#ifdef PIPELINED
  unsigned char unused;
#endif
  // Warming up caches (dunno if it's actually useful for Leon)
  for (int i = 0; i < NB_PRIMITIVE_RUN; i++)
#ifdef PIPELINED
    AES_protected(input,key,output,&unused);
#else
    AES_unprotected(input,key,output);
#endif

#ifdef X86
  unsigned long timer = _rdtsc();
#else
  timer_lap();
#endif

  for (int i = 0; i < NB_PRIMITIVE_RUN; i++)
#ifdef PIPELINED
    AES_protected(input,key,output,&unused);
#else
    AES_unprotected(input,key,output);
#endif

#ifdef X86
  timer = _rdtsc() - timer;
  printf("bench_primitive: %lu cycles/aes (%lu cycles/byte).\n",
         timer/NB_PRIMITIVE_RUN, timer/NB_PRIMITIVE_RUN/16/32);
#else
  unsigned int timer = timer_lap();
  printf("bench_primitive: %x (/10/16/32)\n",timer);
#endif

}


int main() {
  printf("\n" IMPLEM_NAME ":\n");

  test_AES_ref_input();

  bench_full();
  bench_AES_primitive();

  return 0;
}
