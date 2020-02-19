#ifndef KEYMILL_H
#define KEYMILL_H

void keymill_input_key(unsigned d[4]);
void keymill_input_iv(unsigned d[4]);
void start_keymill();
void reset_keymill();
unsigned keymill_output();

#endif
