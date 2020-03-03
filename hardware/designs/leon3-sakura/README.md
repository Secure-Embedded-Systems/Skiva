# Design Directory for port of Skiva on Sakura-G FPGA board

Top Level file is leon3mp.vhd
Synthesis can be triggered using command "make ise" 

## Pin Mapping

| Skiva pin     | Function                               | Sakura-G pin     |
|---------------|----------------------------------------|------------------|
| btnCpuResetn  | Global Reset                           | SW3              |
| clk           | External input clock                   | J4               |
| RsRx          | AHBUART receive                        | CN3.2            |
| RsTx          | AHBUART transmit                       | CN3.4            |
| rxd1          | APBUART receive                        | CN3.6            |
| txd1          | APBUART transmit                       | CN3.8            |
| gpio[0]       | GPIO                                   | CN3.23           |
| gpio[1]       | GPIO                                   | LED4             |
| gpio[2]       | GPIO                                   | LED5             |
| gpio[3]       | GPIO                                   | LED6             |
| gpio[4]       | GPIO                                   | LED7             |
| gpio[5]       | GPIO                                   | LED8             |
| gpio[6]       | GPIO                                   | LED9             |
| gpio[7]       | GPIO                                   | LED10            |

## Communicating with the board using GRMON
GRMON is provided in https://www.gaisler.com/index.php/downloads/debug-tools as a free debug tool which can connect to the debug UART on LEON3 and program the processor core.
After installing the GRMON tool and programming the board with the .bit file, connect the debug UART to the system running the GRMON tool. Give the appropriate access rights to the USB port connected to the debug UART and run grmon. For example for debug UART connected to /dev/ttyUSB0:
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

