#include "gpio.h"

#define GPIO_BASE_ADDR 0x80000500
#define NUM_GPIO 8

typedef enum {
DIN,
DOUT,
DIRECTION,
IMASK,
LEVEL,
EDGE,
BYPASS,
RESERVED,
IRQMAP} GPIOREGID_T;

#define GPIOREG (((volatile unsigned *) GPIO_BASE_ADDR))


void set_gpio_pin_dir(unsigned gpio_num, unsigned dir) {
  if(gpio_num < NUM_GPIO) {
    if(dir==0)
      GPIOREG[DIRECTION] = GPIOREG[DIRECTION] & ~(0x1 << gpio_num);
    else if(dir==1)
      GPIOREG[DIRECTION] = GPIOREG[DIRECTION] | (0x1 << gpio_num);
  }
}

void set_gpio_dir(unsigned dir) {
  if(dir==0)
    GPIOREG[DIRECTION] = 0x0;
  else if(dir==1)
    GPIOREG[DIRECTION] = 0xFFFFFFFF;
}


void set_gpio_pin_output(unsigned gpio_num, unsigned value) {
  if(gpio_num < NUM_GPIO)  {
      if(value==0)
	GPIOREG[DOUT] = GPIOREG[DOUT] & ~(0x1 << gpio_num);
      else if(value==1)
	GPIOREG[DOUT] = GPIOREG[DOUT] | (0x1 << gpio_num);
    }
}

void set_gpio_output(unsigned value) {
  if(value < (0x1<<NUM_GPIO)) {
    GPIOREG[DOUT] = value;
  }
}

unsigned get_gpio_input() {
  return GPIOREG[DIN]; 
}
