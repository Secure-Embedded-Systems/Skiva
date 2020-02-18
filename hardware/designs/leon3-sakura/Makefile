GRLIB=../..
TOP=leon3mp
TECHNOLOGY=spartan6
PART=XC6SLX75
PACKAGE=csg484
SPEED=-2
DEVICE=$(PART)-$(PACKAGE)$(SPEED)

UCF=$(TOP).ucf
UCF_PLANAHEAD=$(UCF)
EFFORT=high
VHDLSYNFILES=config.vhd ahbrom.vhd leon3mp.vhd
VHDLSIMFILES=testbench.vhd
SIMTOP=testbench
CLEAN=soft-clean
TECHLIBS = unisim 

# Libraries, directories and files in GRLIB that should not be compiled for this design
LIBSKIP = core1553bbc core1553brm core1553brt gr1553 corePCIF \
	tmtc openchip ihp usbhc spw
DIRSKIP = b1553 pci/pcif leon2 leon2ft crypto satcan pci leon3ft ambatest can \
	usb grusbhc spacewire ascs slink hcan \
	leon4 leon4v0 l2cache pwm gr1553b iommu
FILESKIP = grcan.vhd

include $(GRLIB)/bin/Makefile 
include $(GRLIB)/software/leon3/Makefile

##################  project specific targets ##########################


#################################################################
# Make prog.mem from main.c
#################################################################
XCC=sparc-elf-gcc
XDUMP=sparc-elf-objdump -dS
XCOPY=sparc-elf-objcopy
IHEXTOMEM=perl ihex2mem.pl
XARGS=-O ihex
XCFLAGS=-O2 -g -msoft-float
SRC=main.c

prog.exe: $(SRC) 
	$(XCC) $(XCFLAGS) $< -o prog.exe 

prog.ihex: prog.exe 
	$(XCOPY) $(XARGS) $< prog.ihex

prog.mem: prog.ihex prog.S
	$(IHEXTOMEM) prog	

prog.S: prog.exe
	$(XDUMP) $< > prog.S

prog_clean:
	rm -rf prog*.mem prog.exe prog.ihex prog.S

#################################################################
# compile vsim 
#################################################################
sim-rtl:
	make vsim

sim-gate:
	make vsim-netgen-par

sim-rtl-launch: vsim
	vsim work.testbench -do run.tcl

sim-rtl-run: vsim
	vsim -c work.testbench -do run.tcl | tee out.txt

sim-gate-launch: vsim
	vsim work.testbench -do gatelevel.do 

