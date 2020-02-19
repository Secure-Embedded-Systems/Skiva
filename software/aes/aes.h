#pragma once

#include "FAME.h"

// defined in aesround-xxx.c
void round__ (/*inputs*/ DATATYPE plain__[128],DATATYPE key__[128], /*outputs*/ DATATYPE cipher__[128]);
void lastround__ (/*inputs*/ DATATYPE plain__[128],DATATYPE key__[128], /*outputs*/ DATATYPE cipher__[128]);


// defined in aes.c
int AES_protected(DATATYPE plain[128], DATATYPE key[11][128], DATATYPE cipher[128], unsigned char* canary);
int AES_unprotected(DATATYPE plain[128], DATATYPE key[11][128], DATATYPE cipher[128]);
int AES_wrapper(DATATYPE* plain, DATATYPE key[11][128], DATATYPE* cipher);
int AES_encrypt_data(unsigned char* input, unsigned char char_key[16],
                     unsigned char* output, unsigned int length);
