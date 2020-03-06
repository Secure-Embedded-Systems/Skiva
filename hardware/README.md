Hardware design of Skiva 
===
![arch](https://github.com/Secure-Embedded-Systems/Skiva/blob/master/doc/diagram.png)
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

## Address Map of Skiva

| Module      | Address Information                               |
|-------------|---------------------------------------------------|
| ahb0        | Aeroflex Gaisler  AHB arbiter/mutiplexer          |
|             | I/O area: 0xfff00000 - 0xffffffff                 |
| u0          | Skiva Processor Core                              |
|             | AHB Master 0                                      |
| dcom0       | Aeroflex Gaisler  AHB Debug UART                  |
|             | AHB Master 1                                      |
|             | APB Slave 2                                       |
|             | APB: 80000300 - 800003ff                          |
| dcom1       | Aeroflex Gaisler  AHB Debug UART                  |
|             | AHB Master 2                                      |
|             | APB Slave 3                                       |
|             | APB: 80000400 - 800004ff                          |
| apbctrl0    | Aeroflex Gaisler  AHB/APB Bridge                  |
|             | AHB Slave 1                                       |
|             | APB Master 0                                      |
|             | AHB: 80000000 - 800fffff                          |
| dsu0        | Aeroflex Gaisler  LEON3 Debug Support Unit        |
|             | AHB Slave 1                                       |
|             | AHB: 90000000 - 9fffffff                          |
|             | CPU0:  win 8, hwbp 2, itrace 64, lddel 1          |
|             | stack pointer 0x4001fff0                          |
|             | icache 1 * 1 kB, 16 B/line                        |
|             | dcache 1 * 1 kB, 16 B/line                        |
| ahbrom0     | Aeroflex Gaisler  Generic AHB ROM                 |
|             | AHB Slave 2                                       |
|             | AHB: 00000000 - 000fffff                          |
| ahbram0     | Aeroflex Gaisler  Single-port AHB SRAM module     |
|             | AHB Slave 3                                       |
|             | AHB: 40000000 - 400fffff                          |
|             | 32-bit static ram: 128 kB @ 0x40000000            |
| spimctrl0   | Aeroflex Gaisler  SPI Memory Controller           |
|             | AHB Slave 4                                       |
|             | AHB: FFF00200 - FFF002ff (I/O part)               |
|             | AHB: 10000000 - 10ffffff (Memory part)            |
| uart1       | Aeroflex Gaisler  Generic UART                    |
|             | APB Slave 0                                       |
|             | APB: 80000100 - 800001ff                          |
| irqmp0      | Aeroflex Gaisler  Multi-processor Interrupt Ctrl. |
|             | APB Slave 1                                       |
|             | APB: 80000200 - 800002ff                          |
| gpio0       | Aeroflex Gaisler  General Purpose I/O port        |
|             | APB Slave 4                                       |
|             | APB: 80000500 - 800005ff                          |
| gptimer0    | Aeroflex Gaisler  Modular Timer Unit              |
|             | APB Slave 5                                       |
|             | APB: 80000600 - 800006ff                          |
|             | 32-bit scalar, 5 * 32-bit timers, divisor 24      |

## Encoding of the New Instructions
The encoding of the custom instructions follows that of format 3 instructions in SPARC v8. The figure below shows the encoding.

![](https://github.com/Secure-Embedded-Systems/Skiva/blob/master/doc/format3.png) The encoding of format 3 SPARC v8 instructions.

The following table shows the opcodes assigned to each custom instruction.

| Instruction   | op  | op3   | i  |
| ------------- |:---:| :----:|:--:|
| TR2           | 10  | 0x1d  |0   |
| INVTR2        | 10  | 0x19  |0   |
| SUBROT        | 10  | 0x09  |1   |
| RED           | 10  | 0x0d  |1   |
| FTCHK         | 10  | 0x2e  |1   |
| ANDC8         | 11  | 0x08  |0   |
| XORC8         | 11  | 0x0c  |0   |
| XNORC8        | 11  | 0x18  |0   |
| ANDC16        | 11  | 0x0b  |0   |
| XORC16        | 11  | 0x0e  |0   |
| XNORC16       | 11  | 0x1b  |0   |
