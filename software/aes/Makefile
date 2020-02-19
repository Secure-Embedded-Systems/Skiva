# To compile on X86, you can use the following line:
#   make BCC='gcc' LDFLAGS='' CFLAGS='-Wall -Wextra -I../arch -Os -D X86'
BCC=sparc-gaisler-elf-gcc -mcpu=leon3 -mno-fpu
LDFLAGS=-L../FPGA-API/lib -lfame
CFLAGS=-Wall -Wextra -Wno-unused-function -I../arch -I../FPGA-API/include
PIPELINED=-D PIPELINED
IMPLEM=-D COMPACT
CUSTOM_INSTR=
IMPLEM_NAME=main
OPTI_FLAG=-Os
TI=4
FD=4
RAND= #-D CST_RAND

USUBA= # Path to Usuba compiler
UFLAGS=-bits-per-reg 32 -no-sched -no-share -fdti 1

all: main

aesround.c: aesround.ua
	$(USUBA) $(UFLAGS) -o $@ $<

main: aes.c bs.c key_sched.c main.c fame_lib.c
	$(BCC) $(CFLAGS) $(OPTI_FLAG) -D TI=$(TI) -D FD=$(FD) $(IMPLEM) $(CUSTOM_INSTR) $(PIPELINED) -D IMPLEM_NAME='"$(IMPLEM_NAME)"' $^ -o $@ $(LDFLAGS)

clean:
	rm -f main
