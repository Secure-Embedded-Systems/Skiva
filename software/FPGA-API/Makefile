LDFLAGS= -lm
CFLAGS= -O2 -Wall -Iinclude
CC=sparc-gaisler-elf-gcc
CCAR=sparc-gaisler-elf-ar
XDUMP=sparc-gaisler-elf-objdump -dS
XCOPY=sparc-gaisler-elf-objcopy

IHEXTOMEM=perl ../../../bin/ihex2mem.pl
MEMTOMEM=perl ../../../bin/mem2mem.pl
XARGS=-O ihex
XCFLAGS=-O2 -g -msoft-float


src = 	src/gptimer.c \
		src/aescoproc.c \
		src/keymill.c \
		src/gpio.c \
		src/uart.c \
		src/irqmp.c

header = 	include/gptimer.h \
			include/aescoproc.h \
			include/keymill.h \
			include/gpio.h \
			include/uart.h \
			include/irqmp.h
obj = $(src:.c=.o)

.c.o:
	$(CC) -c -o $@ $(CFLAGS) $<

all:
	@echo "Targets: "
	@echo "  compile    Compile software packages"
	@echo "  clean      Remove intermediate files"

compile: libfame.a

libfame.a : $(obj)
	$(CCAR) r lib/$@ $(obj)

clean:
	rm -rf src/*.o lib/*.a
