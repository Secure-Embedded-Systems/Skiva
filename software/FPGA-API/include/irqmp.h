#ifndef IRQMP_H
#define IRQMP_H

void init_irqmp();
void set_interrupt_level(unsigned int interrupt, unsigned int level);
void force_interrupt(unsigned int interrupt);
char clear_interrupt(unsigned int interrupt);
void mask_interrupt(unsigned int interrupt);
unsigned int check_pending_interrupts();

#endif
