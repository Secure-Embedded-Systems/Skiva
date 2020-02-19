#include "keymill.h"

#define KEYMILL_BASE_ADDR 0x80014000


typedef enum {
CONTROL,
INPUT_KEY0,
INPUT_KEY1,
INPUT_KEY2,
INPUT_KEY3,
INIT_VECTOR0,
INIT_VECTOR1,
INIT_VECTOR2,
INIT_VECTOR3,
DUMMY,
OUTPUT} KEYMILLREGID_T;

#define KEYMILLREG (((volatile unsigned *) KEYMILL_BASE_ADDR))

void keymill_input_key(unsigned d[4]) {
  KEYMILLREG[INPUT_KEY0] = d[0];
  KEYMILLREG[INPUT_KEY1] = d[1];
  KEYMILLREG[INPUT_KEY2] = d[2];
  KEYMILLREG[INPUT_KEY3] = d[3];
}

void keymill_input_iv(unsigned d[4]) {
  KEYMILLREG[INIT_VECTOR0] = d[0];
  KEYMILLREG[INIT_VECTOR1] = d[1];
  KEYMILLREG[INIT_VECTOR2] = d[2];
  KEYMILLREG[INIT_VECTOR3] = d[3];
}

void start_keymill() {
  KEYMILLREG[CONTROL] = 0x00000001;
}

void reset_keymill() {
  KEYMILLREG[CONTROL] = 0x00000002;
}

unsigned keymill_output() {	
  unsigned output;
  while((KEYMILLREG[CONTROL] & 0x80000000) != 0);
  while((KEYMILLREG[CONTROL] & 0x40000000) != 0);
  output = KEYMILLREG[OUTPUT];
  return output;
}


/* API for L-R Keymill coprocessor
Following is sample code for using this API

void main()
{

	int i; char j;
	unsigned int output;
	char key[16];
	char input[16];
	for(j=0; j<16;j++)
		key[j] = 'A'+j;
	for(j=0; j<16;j++)
		input[j] = 'B';
	
	reset_keymill();
	keymill_input_key(key);
	keymill_input_iv(input);
	start_keymill();
	//output = keymill_output();
	for(i=0;i<128;i++)
	{
		output = keymill_output();
		printf("\nKeymill output %d : %u", i, output);
	}
}
*/

