#include "aescoproc.h"

#define AES_BASE_ADDR 0x80013000

/************************************************/
/*--------------Register Space------------------*/

/* base_ptr - Control Reg - Bits 31-5 -> 0
 *                          Bits 4-3 -> AES Mode (00-ECB, 01-CBC)
 *                          Bit 2 -> encr/decr (1-encrypt, 0-decrypt) 
 *                          Bit 1 -> Inputs valid (assert to begin coprocessor operation)
 *                          Bit 0 -> Soft rst
 *
 * base_ptr[1] - Key word 0
 * base_ptr[2] - Key word 1
 * base_ptr[3] - Key word 2
 * base_ptr[4] - Key word 3
 *
 * base_ptr[5] - Input text word 0
 * base_ptr[6] - Input text word 1
 * base_ptr[7] - Input text word 2
 * base_ptr[8] - Input text word 3
 *
 * base_ptr[9] - IV word 0
 * base_ptr[10] - IV word 1
 * base_ptr[11] - IV word 2
 * base_ptr[12] - IV word 3
 *
 * base_ptr[13] - Output text word 0
 * base_ptr[14] - Output text word 1
 * base_ptr[15] - Output text word 2
 * base_ptr[16] - Output text word 3
 *
 * base_ptr[17] - Status Reg - Bits 31:1 -> 0
 *                             Bit 0 -> output ready
 *                              
 ***************************************************/                               
typedef enum {
	      CONTROL,
	      KEY0,
	      KEY1,
	      KEY2,
	      KEY3,
	      IN_DATA0,
	      IN_DATA1,
	      IN_DATA2,
	      IN_DATA3,
	      INIT_VECTOR0,
	      INIT_VECTOR1,
	      INIT_VECTOR2,
	      INIT_VECTOR3,
	      OUT_DATA0,
	      OUT_DATA1,
	      OUT_DATA2,
	      OUT_DATA3,
	      STATUS} AESREGID_T;

#define AESREG (((volatile unsigned *) AES_BASE_ADDR))

void aes_set_key(unsigned d[4]) {
  AESREG[KEY0] = d[0];
  AESREG[KEY1] = d[1];
  AESREG[KEY2] = d[2];
  AESREG[KEY3] = d[3];
}

void aes_set_input_data(unsigned d[4]) {
  AESREG[IN_DATA0] = d[0];
  AESREG[IN_DATA1] = d[1];
  AESREG[IN_DATA2] = d[2];
  AESREG[IN_DATA3] = d[3];
}

void aes_set_iv(unsigned d[4]) {
  AESREG[INIT_VECTOR0] = d[0];
  AESREG[INIT_VECTOR1] = d[1];
  AESREG[INIT_VECTOR2] = d[2];
  AESREG[INIT_VECTOR3] = d[3];
}

void     aes_encrypt_ecb() {
  AESREG[CONTROL] = 0x6;
  AESREG[CONTROL] = 0x4;
  while (AESREG[STATUS] != 0x00000001);
}

void     aes_decrypt_ecb() {
  AESREG[CONTROL] = 0x2;
  AESREG[CONTROL] = 0x0;
  while (AESREG[STATUS] != 0x00000001);
}

void     aes_encrypt_cbc() {
  AESREG[CONTROL] = 0xE;
  AESREG[CONTROL] = 0xC;
  while (AESREG[STATUS] != 0x00000001);
}

void     aes_decrypt_cbc() {
  AESREG[CONTROL] = 0xA;
  AESREG[CONTROL] = 0x8;
  while (AESREG[STATUS] != 0x00000001);
}

void aes_soft_reset() {
  AESREG[CONTROL] = 0x1;
  AESREG[CONTROL] = 0x0;
}

void aes_get_output_data(unsigned d[4]) {
  d[0] = AESREG[OUT_DATA0];
  d[1] = AESREG[OUT_DATA1];
  d[2] = AESREG[OUT_DATA2];
  d[3] = AESREG[OUT_DATA3];
}

