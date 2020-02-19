#include "uart.h"

#define BAUDRATE 38400
#define SYS_CLK 50
#define UART_BASE_ADDR 0x80000100

typedef enum {
DATA,
STATUS,
CONTROL,
SCALER,
FIFO_DEBUG } UARTREGID_T;

#define UARTREG (((volatile unsigned *) UART_BASE_ADDR))
void init_uart() {
  UARTREG[DATA] = 0; //Clear the data register
  UARTREG[SCALER] = (SYS_CLK*1000000)/(BAUDRATE*8+7);//Set scaler value according to system clock and baudrate
  UARTREG[CONTROL] = 0x3;	//Enable transmitter and receiver
}

void set_baudrate_uart(int baudrate) {
  UARTREG[SCALER] = (SYS_CLK*1000000)/(baudrate*8+7);  
}

void put_char_uart(char a) {
  while(UARTREG[STATUS] & (1<<9)); //Wait if transmission fifo is full
  UARTREG[DATA] = a;
}

char get_char_uart() {
  while(!(UARTREG[STATUS] & 0x1)); //Wait till data ready
  return UARTREG[DATA]; 
  
}

void put_string_uart(char* input_string, int size) {
  int i;
  for(i=0;i<size;i++) {
    put_char_uart(input_string[i]);
  }	
}

void get_string_uart(char* output_string,int size) {
  int i;
  for (i=0;i<size;i++) {	
    output_string[i] = get_char_uart();
  }
}	

/* API for APBUART peripheral
void main()
{	
	volatile long long cnt;
	init_uart();
	for(cnt=0;cnt<100;cnt++)
		put_char_uart('A');
	printf("input_char: %c",get_char_uart());
	char test[] = "Tarun";
	put_string_uart(test,5);
	char* output = (char*)malloc(5);
	get_string_uart(output,5);
	for(cnt=0; cnt<5;cnt++)
	printf("input_string: %c",output[cnt]);
	free(output);
}	
*/
