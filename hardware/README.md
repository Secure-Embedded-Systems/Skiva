Hardware design files of Skiva 
===
(https://github.com/Secure-Embedded-Systems/Skiva/blob/master/doc/diagram.png)
## Organization 
This repository includes hardware design files for the Skiva project, building upon the FAME-v2 specific modified version of GRLIB library of Cobham Gaisler. The repository adopts the file hierarchy of the original GRLIB distribution:
* bin:			various scripts and tool support files
* designs:		template design files for FPGA prototyping boards
* lib: 			VHDL libraries

## Tool requirements 
* Xilinx ISE: To generate programmable file for SAKURA-G FPGA board. For this project, we used the 14.7 version of ISE. 
* Quartus: To genenerate the programmable file for DE2 FPGA board. For this project, we used the 17.0 version of Quartus. 

## Getting started
### SAKURA-G board
To get the programmable file for Sakura-G FPGA board, run the following commands:
```sh
$ cd designs/leon3-sakura/
$ make ise
```
The output file is leon3mp.bit and can be programmed on the main FPGA on Sakura-G board.
### DE2 board
To get the programmable file for DE2 FPGA board, run the following commands:
```sh
$ cd designs/leon3-terasic-de2-115/
$ make quartus
```
The generated programmable files LEON3_DE2115_quartus.sof and LEON3_DE2115_quartus.pof can be used to program the DE2 board.

### Ready programmable files
In case you cannot generate the programmable files, you can use the ones available in folder. 


### Communicating with the board using GRMON
GRMON is provided in https://www.gaisler.com/index.php/downloads/debug-tools as a free debug tool which can connect to the debug UART on LEON3 and program the processor core.

After installing the GRMON tool and programming the board with the programmable file, connect the debug UART to the system running the GRMON tool. Give the appropriate access rights to the USB port connected to the debug UART and run grmon. For example for debug UART connected to /dev/ttyUSB0:
```sh
$ sudo chmod 777 /dev/ttyUSB0
$ grmon -u -uart /dev/ttyUSB0 
  GRMON debug monitor v3.2.1 64-bit eval version
  
  Copyright (C) 2020 Cobham Gaisler - All rights reserved.
  For latest updates, go to http://www.gaisler.com/
  Comments or bug-reports to support@gaisler.com
  
  This eval version will expire on 14/08/2020

  using port /dev/ttyUSB0 @ 115200 baud
  GRLIB build version: 4144
  Detected frequency:  10.0 MHz
  
  Component                            Vendor
  LEON3 SPARC V8 Processor             Cobham Gaisler
  AHB Debug UART                       Cobham Gaisler
  JTAG Debug Link                      Cobham Gaisler
  AHB/APB Bridge                       Cobham Gaisler
  LEON3 Debug Support Unit             Cobham Gaisler
  SPI Memory Controller                Cobham Gaisler
  Generic AHB ROM                      Cobham Gaisler
  Single-port AHB SRAM module          Cobham Gaisler
  AHB/APB Bridge                       Cobham Gaisler
  AHB/APB Bridge                       Cobham Gaisler
  Generic UART                         Cobham Gaisler
  Multi-processor Interrupt Ctrl.      Cobham Gaisler
  General Purpose I/O port             Cobham Gaisler
  Modular Timer Unit                   Cobham Gaisler
  
  Use command 'info sys' to print a detailed report of attached cores
  
grmon3> load /home/test/main.exe


          40000000 .text             28.8kB /  28.8kB   [===============>] 100%
          40007350 .rodata            800B              [===============>] 100%
          40007670 .data              1.2kB /   1.2kB   [===============>] 100%
  Total size: 30.77kB (105.70kbit/s)
  Entry point 0x40000000
  Image /home/test/main.exe loaded
  
grmon3> run

```


