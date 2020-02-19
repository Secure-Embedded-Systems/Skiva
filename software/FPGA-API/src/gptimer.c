#include "gptimer.h"

#define ADDR 0x80000600

typedef struct {
    volatile unsigned int counter;		/* 0x0 */
    volatile unsigned int reload;		/* 0x4 */
    volatile unsigned int control;		/* 0x8 */
    volatile unsigned int latch;		/* 0xC */
} timerreg;

typedef struct {
    volatile unsigned int scalercnt;		/* 0x00 */
    volatile unsigned int scalerload;		/* 0x04 */
    volatile unsigned int configreg;		/* 0x08 */
    volatile unsigned int latch;		/* 0x0C */
    timerreg timer[7];
} gptimer;

// Timer ticks every 10 cycles
#define RESOLUTION 9
#define MAX_VALUE 0xFFFFFFFF

unsigned int ntimers() {
  gptimer *lr = (gptimer *) ADDR;

  return (lr->configreg & 0x7); //Find number of counters configured.
}

void timer_start() {
  gptimer *lr = (gptimer *) ADDR;

  lr->scalerload       = RESOLUTION;
  lr->timer[0].reload  = MAX_VALUE;
  lr->timer[0].control = lr->timer[0].control | 0x7;
}

void timer_stop() {
  gptimer *lr = (gptimer *) ADDR;

  lr->timer[0].control = 0;
}

unsigned long timer_lap() {
  gptimer *lr = (gptimer *) ADDR;

  static unsigned long count = 0;

  unsigned long int lap;
  lap = (unsigned long) (count - lr->timer[0].counter);
  count = lr->timer[0].counter;
  return lap;
}
