#ifndef GPIO_H
#define GPIO_H

void set_gpio_pin_dir(unsigned gpio_num, unsigned dir);
void set_gpio_dir(unsigned dir);
void set_gpio_pin_output(unsigned gpio_num, unsigned value);
void set_gpio_output(unsigned value);
unsigned get_gpio_input();

#endif
