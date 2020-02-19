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
#include "faults_inputs.h"

  unsigned char output[16*32];
  int res = AES_encrypt_data(input,key,output,4*128);
  if (res) {
    printf("Fault detected.\n");
  }

  if (fame_memcmp(output,output_ref,16*32) != 0) {
    printf("Error.\n");
  } else {
    printf("AES seems correct.\n");
  }

}


int main() {
  int r = 0;

  printf("\n" IMPLEM_NAME ":\n");

  test_AES_ref_input();

  return r;
}
