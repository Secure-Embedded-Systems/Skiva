
/* Contains functions to add TI and FD to some data, to remove them,
   and to bitslice data. */

#include "fame_lib.h"
#include "FAME.h"

/* Inserts redundancy and shares */
static void normal_to_tifd(DATATYPE* input,DATATYPE output[128]) {
  
#if TI == 1 && FD == 1
  for (int i = 0; i < 32; i++)
    for (int j = 0; j < 4; j++)
      output[i+j*32] = input[i*4+j];
#elif TI == 2 && FD == 1
  for (int i = 0; i < 16; i++)
    for (int j = 0; j < 4; j++) {
      DATATYPE randShare = RAND();
      output[i*2+j*32]   = randShare ^ input[i*4+j];
      output[i*2+j*32+1] = randShare;
    }
#elif TI == 4 && FD == 1
  for (int i = 0; i < 8; i++)
    for (int j = 0; j < 4; j++) {
      DATATYPE randShare1 = RAND(),randShare2 = RAND(), randShare3 = RAND();
      output[i*4+j*32]   = randShare1 ^ randShare2 ^ randShare3 ^ input[i*4+j];
      output[i*4+j*32+1] = randShare1;
      output[i*4+j*32+2] = randShare2;
      output[i*4+j*32+3] = randShare3;
    }
#elif TI == 1 && FD == 2
  for (int i = 0; i < 16; i++)
    for (int j = 0; j < 4; j++) {
      output[i+j*32]    =  input[i*4+j];
      output[i+j*32+16] = ~input[i*4+j];
    }
#elif TI == 1 && FD == 4
  for (int i = 0; i < 8; i++)
    for (int j = 0; j < 4; j++) {
      output[i+j*32]    =  input[i*4+j];
      output[i+j*32+8]  = ~input[i*4+j];
      output[i+j*32+16] =  input[i*4+j];
      output[i+j*32+24] = ~input[i*4+j];
    }
#elif TI == 2 && FD == 2
  for (int i = 0; i < 8; i++)
    for (int j = 0; j < 4; j++) {
      DATATYPE randShare = RAND();
      output[i*2+j*32]    =  randShare ^ input[i*4+j];
      output[i*2+j*32+1]  =  randShare;
      output[i*2+j*32+16] = ~(randShare ^ input[i*4+j]);
      output[i*2+j*32+17] = ~randShare;
    }
#elif TI == 4 && FD == 2
  for (int i = 0; i < 4; i++)
    for (int j = 0; j < 4; j++) {
      DATATYPE randShare1 = RAND(),randShare2 = RAND(), randShare3 = RAND();
      output[i*4+j*32]    =  randShare1 ^ randShare2 ^ randShare3 ^ input[i*4+j];
      output[i*4+j*32+1]  =  randShare1;
      output[i*4+j*32+2]  =  randShare2;
      output[i*4+j*32+3]  =  randShare3;
      output[i*4+j*32+16] = ~(randShare1 ^ randShare2 ^ randShare3 ^ input[i*4+j]);
      output[i*4+j*32+17] = ~randShare1;
      output[i*4+j*32+18] = ~randShare2;
      output[i*4+j*32+19] = ~randShare3;
    }
#elif TI == 2 && FD == 4
  for (int i = 0; i < 4; i++)
    for (int j = 0; j < 4; j++) {
      DATATYPE randShare  = RAND();
      output[i*2+j*32]    =  randShare ^ input[i*4+j];
      output[i*2+j*32+1]  =  randShare;
      output[i*2+j*32+8]  = ~(randShare ^ input[i*4+j]);
      output[i*2+j*32+9]  = ~randShare;
      output[i*2+j*32+16] =  randShare ^ input[i*4+j];
      output[i*2+j*32+17] =  randShare;
      output[i*2+j*32+24] = ~(randShare ^ input[i*4+j]);
      output[i*2+j*32+25] = ~randShare;
    }
#elif TI == 4 && FD == 4
  for (int i = 0; i < 2; i++)
    for (int j = 0; j < 4; j++) {
      DATATYPE randShare1 = RAND(),randShare2 = RAND(), randShare3 = RAND();
      output[i*4+j*32]    =  randShare1 ^ randShare2 ^ randShare3 ^ input[i*4+j];
      output[i*4+j*32+1]  =  randShare1;
      output[i*4+j*32+2]  =  randShare2;
      output[i*4+j*32+3]  =  randShare3;
      output[i*4+j*32+8]  = ~(randShare1 ^ randShare2 ^ randShare3 ^ input[i*4+j]);
      output[i*4+j*32+9]  = ~randShare1;
      output[i*4+j*32+10] = ~randShare2;
      output[i*4+j*32+11] = ~randShare3;
      output[i*4+j*32+16] =  randShare1 ^ randShare2 ^ randShare3 ^ input[i*4+j];
      output[i*4+j*32+17] =  randShare1;
      output[i*4+j*32+18] =  randShare2;
      output[i*4+j*32+19] =  randShare3;
      output[i*4+j*32+24] = ~(randShare1 ^ randShare2 ^ randShare3 ^ input[i*4+j]);
      output[i*4+j*32+25] = ~randShare1;
      output[i*4+j*32+26] = ~randShare2;
      output[i*4+j*32+27] = ~randShare3;
    }
#endif
  
}

/* Removes redundancy and shares */
static void tifd_to_normal(DATATYPE input[128],DATATYPE* output) {
  
#if TI == 1 && FD == 1
  for (int i = 0; i < 32; i++)
    for (int j = 0; j < 4; j++)
      output[i*4+j] = input[i+j*32];
#elif TI == 2 && FD == 1
  for (int i = 0; i < 16; i++)
    for (int j = 0; j < 4; j++)
      output[i*4+j] = input[i*2+j*32] ^ input[i*2+j*32+1];
#elif TI == 4 && FD == 1
  for (int i = 0; i < 8; i++)
    for (int j = 0; j < 4; j++)
      output[i*4+j] = input[i*4+j*32]   ^ input[i*4+j*32+1] ^
                      input[i*4+j*32+2] ^ input[i*4+j*32+3] ;
#elif TI == 1 && FD == 2
  for (int i = 0; i < 16; i++)
    for (int j = 0; j < 4; j++)
      output[i*4+j] = input[i+j*32];
#elif TI == 1 && FD == 4
  for (int i = 0; i < 8; i++)
    for (int j = 0; j < 4; j++)
      output[i*4+j] = input[i+j*32];
#elif TI == 2 && FD == 2
  for (int i = 0; i < 8; i++)
    for (int j = 0; j < 4; j++)
      output[i*4+j] = input[i*2+j*32] ^ input[i*2+j*32+1];
#elif TI == 4 && FD == 2
  for (int i = 0; i < 4; i++)
    for (int j = 0; j < 4; j++)
      output[i*4+j] = input[i*4+j*32]   ^ input[i*4+j*32+1] ^
                      input[i*4+j*32+2] ^ input[i*4+j*32+3];
#elif TI == 2 && FD == 4
  for (int i = 0; i < 4; i++)
    for (int j = 0; j < 4; j++)
      output[i*4+j] = input[i*2+j*32] ^ input[i*2+j*32+1];
#elif TI == 4 && FD == 4
  for (int i = 0; i < 2; i++)
    for (int j = 0; j < 4; j++)
      output[i*4+j] = input[i*4+j*32]   ^ input[i*4+j*32+1] ^
                      input[i*4+j*32+2] ^ input[i*4+j*32+3];
#endif

}

#if defined(X86) || defined(NO_CUSTOM_INSTR)
/* Orthogonalization stuffs */
static unsigned int mask_l[5] = {
	0xaaaaaaaa,
	0xcccccccc,
	0xf0f0f0f0,
	0xff00ff00,
	0xffff0000
};

static unsigned int mask_r[5] = {
	0x55555555,
	0x33333333,
	0x0f0f0f0f,
	0x00ff00ff,
	0x0000ffff
};


static void to_bitslice32x32(unsigned int data[]) {
  for (int i = 0; i < 5; i ++) {
    int n = (1UL << i);
    for (int j = 0; j < 32; j += (2 * n))
      for (int k = 0; k < n; k ++) {
        unsigned int u = data[j + k] & mask_r[i];
        unsigned int v = data[j + k] & mask_l[i];
        unsigned int x = data[j + n + k] & mask_r[i];
        unsigned int y = data[j + n + k] & mask_l[i];
        data[j + k] = u | (x << n);
        data[j + n + k] = (v >> n) | y;
      }
  }
  for (int i = 0; i < 4; i++)
    for (int j = 0; j < 4; j++) {
      DATATYPE tmp = data[i*8+j];
      data[i*8+j] = data[i*8+7-j];
      data[i*8+7-j] = tmp;
    }
}

static void from_bitslice32x32(unsigned int data[]) {
  for (int i = 0; i < 5; i ++) {
    int n = (1UL << i);
    for (int j = 0; j < 32; j += (2 * n))
      for (int k = 0; k < n; k ++) {
        unsigned int u = data[j + k] & mask_l[i];
        unsigned int v = data[j + k] & mask_r[i];
        unsigned int x = data[j + n + k] & mask_l[i];
        unsigned int y = data[j + n + k] & mask_r[i];
        data[j + n + k] = u | (x >> n);
        data[j + k] = (v << n) | y;
      }
  }
}
static void from_bitslice32x322(DATATYPE data[32]) {
  for (int i = 16, n = 1; i > 0; i >>= 1, n++) {
    for (int j = 0; j < i; j++) {
      for (int k = 0; k < 32; k += i*2) {
        DATATYPE low, high;
        TIBS(high,low,data[k+j],data[k+j+i]);
        data[k+j] = low;
        data[k+j+i] = high;
      }
    }
  }
}
#else
/* Transposes (bitslices) an array of 32 int */
void to_bitslice32x32(DATATYPE data[32]) {
  for (int i = 16, n = 1; i > 0; i >>= 1, n++) {
    for (int j = 0; j < i; j++) {
      for (int k = 0; k < 32; k += i*2) {
        DATATYPE low, high;
        TIBS(high,low,data[k+j+i],data[k+j]);
        data[k+j] = low;
        data[k+j+i] = high;
      }
    }
  }
  // Fixing bit endianness within bytes
  // (not strictly necessary, but needed to work with our **current** AES)
  for (int i = 0; i < 4; i++)
    for (int j = 0; j < 4; j++) {
      DATATYPE tmp = data[i*8+j];
      data[i*8+j] = data[i*8+7-j];
      data[i*8+7-j] = tmp;
    }
}
/* Un-transpose an array of 32 int. 
   This is not exactly the inverse of to_bitslice32x32, 
   due to some endianess stuffs.
   (In particular, data[k+j], and data[k+j+i] are inverted in the call to TIBS)
 */
void from_bitslice32x32(DATATYPE data[32]) {
  for (int i = 16, n = 1; i > 0; i >>= 1, n++) {
    for (int j = 0; j < i; j++) {
      for (int k = 0; k < 32; k += i*2) {
        DATATYPE low, high;
        TIBS(high,low,data[k+j],data[k+j+i]);
        data[k+j] = low;
        data[k+j+i] = high;
      }
    }
  }
}
#endif


/* Transposes 128 int */
static void to_bitslice(DATATYPE data[128]) {
  to_bitslice32x32(data);
  to_bitslice32x32(&data[32]);
  to_bitslice32x32(&data[64]);
  to_bitslice32x32(&data[96]);
}

/* Un-transposes 128 int */
static void from_bitslice(DATATYPE data[128]) { 
  from_bitslice32x32(data);
  from_bitslice32x32(&data[32]);
  from_bitslice32x32(&data[64]);
  from_bitslice32x32(&data[96]);
}

/* Add redundancy/sharing, then bitslice */
void normal_to_bs(DATATYPE* input, DATATYPE output[128]) {
  normal_to_tifd(input,output);
  to_bitslice(output);
}

/* Un-bitslice and then remove redundancy/sharing */
void bs_to_normal(DATATYPE input[128], DATATYPE* output) {
  from_bitslice(input);
  tifd_to_normal(input,output);
}
