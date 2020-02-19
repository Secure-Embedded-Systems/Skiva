#include "irqmp.h"

#define IRQMP_BASE_ADDR 0x80000200

typedef struct {
  volatile unsigned int level;
  volatile unsigned int pending;
  volatile unsigned int force;
  volatile unsigned int clear;
  volatile unsigned int multiproc_status;
  volatile unsigned int broadcast;
  volatile unsigned int error_mode;
  volatile unsigned int dummy1[10];
  volatile unsigned int mask;
} irqmp_reg;

void init_irqmp() {
  irqmp_reg *ptr = (irqmp_reg *)IRQMP_BASE_ADDR;
  ptr->level = 0; 		//Set all interrupts to have level0
  ptr->mask = 0;			//Mask all interrupts at init
  ptr->clear = 0xFFFFFFFE;	//Clear all interrupts
}

void set_interrupt_level(unsigned int interrupt, unsigned int level) {
  irqmp_reg *ptr = (irqmp_reg *)IRQMP_BASE_ADDR;
  if(level==1)
    ptr->level |= (1<<interrupt) ;
  else if(level==0)
    ptr->level &= ~(1<<interrupt);
  
}

void force_interrupt(unsigned int interrupt) {
  irqmp_reg *ptr = (irqmp_reg *)IRQMP_BASE_ADDR;
  ptr->force |= (1<<interrupt); 
}

char clear_interrupt(unsigned int interrupt) {
  irqmp_reg *ptr = (irqmp_reg *)IRQMP_BASE_ADDR;
  ptr->clear |= (1<<interrupt);
  return 0;
}

void mask_interrupt(unsigned int interrupt) {
  irqmp_reg *ptr = (irqmp_reg *)IRQMP_BASE_ADDR;
  ptr->mask &= ~(1<<interrupt);
}

unsigned int check_pending_interrupts() {
  irqmp_reg *ptr = (irqmp_reg *)IRQMP_BASE_ADDR;
  return ptr->pending;	  
}

/*API for the Interrupt controller (IRQMP)
Sample code for using the API along with gptimer API. 
Initialize the timer with a small value and wait for underrun and interrupt to be generated
void main()
{
timer_start();
while(check_pending_interrupts()==0);
printf("interrupts value : %x", check_pending_interrupts());
}
*/

