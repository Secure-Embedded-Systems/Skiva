#ifndef UART_H
#define UART_H

void init_uart();
void set_baudrate_uart(int baudrate);
void put_char_uart(char a);
char get_char_uart();
void put_string_uart(char* input_string, int size);
void get_string_uart(char* output_string,int size);

#endif
