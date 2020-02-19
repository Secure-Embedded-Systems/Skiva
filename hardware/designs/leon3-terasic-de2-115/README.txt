Design Directory for port of FAMEv2 to Altera DE2-115 board

Top Level file is LEON3_DE2115.v
Quartus Project file is LEON3_DE2115_quartus.qpf
Synthesis can be triggered using command "make quartus" 

Pin Mapping:

| FAMEv2 pin    | Function                               | DE2 pin          |
|---------------|----------------------------------------|------------------|
| resetn        | Global Reset                           | KEY[3]           |
| clk           | Input clock                            | CLOCK_50         |
| alarmout      | Alarm Out from leon3 if fault detected | LEDR[13]         |
| DebugUart_RX  | AHBUART receive                        | GPIO[35],LEDG{1] |
| DebugUart_TX  | AHBUART transmit                       | GPIO[33],LEDG[0] |
| PeriphUart_RX | APBUART receive                        | GPIO[29],LEDG[3] |
| PeriphUart_TX | APBUART transmit                       | GPIO[31],LEDG[2] |
| dsuact        | Check if DSU is active                 | LEDR[17]         |
| dsubre        | External Break signal for DSU          | SW[16]           |
| gpio[0]       | GPIO                                   | GPIO[0],LEDR[0]  |
| gpio[1]       | GPIO                                   | GPIO[1],LEDR[1]  |
| gpio[2]       | GPIO                                   | GPIO[2],LEDR[2]  |
| gpio[3]       | GPIO                                   | GPIO[3],LEDR[3]  |
| gpio[4]       | GPIO                                   | GPIO[4],LEDR[4]  |
| gpio[5]       | GPIO                                   | GPIO[5],LEDR[5]  |
| gpio[6]       | GPIO                                   | GPIO[6],LEDR[6]  |
| gpio[7]       | GPIO                                   | GPIO[7],LEDR[7]  |
| triggerout[0] | TriggerOut from leon3                  | GPIO[17]         |
| triggerout[1] | TriggerOut from leon3                  | GPIO[15]         |
| triggerout[2] | TriggerOut from leon3                  | GPIO[13]         |
| triggerout[3] | TriggerOut from leon3                  | GPIO[11]         |
| dsuen         | Enable/Disable DSU                     | SW[17]           |
| errorn        | Error Signal from Leon3                | LEDR[8]          |


$ ./grmon.exe -u -uart //./com7.

  GRMON2 LEON debug monitor v2.0.90 64-bit eval version

  Copyright (C) 2018 Cobham Gaisler - All rights reserved.
  For latest updates, go to http://www.gaisler.com/
  Comments or bug-reports to support@gaisler.com

  This eval version will expire on 22/09/2018

  GRLIB build version: 4144
  Detected frequency:  50 MHz

  Component                            Vendor
  LEON3 SPARC V8 Processor             Cobham Gaisler
  AHB Debug UART                       Cobham Gaisler
  JTAG Debug Link                      Cobham Gaisler
  AHB/APB Bridge                       Cobham Gaisler
  LEON3 Debug Support Unit             Cobham Gaisler
  Generic AHB ROM                      Cobham Gaisler
  Single-port AHB SRAM module          Cobham Gaisler
  Generic UART                         Cobham Gaisler
  Multi-processor Interrupt Ctrl.      Cobham Gaisler
  General Purpose I/O port             Cobham Gaisler
  Modular Timer Unit                   Cobham Gaisler
  Unknown device                       Various contributions
  Unknown device                       Various contributions

  Use command 'info sys' to print a detailed report of attached cores

GRMON Output:

grmon2> info sys
info sys
  cpu0      Cobham Gaisler  LEON3 SPARC V8 Processor
            AHB Master 0
  ahbuart0  Cobham Gaisler  AHB Debug UART
            AHB Master 1
            APB: 80000700 - 80000800
            Baudrate 115200, AHB frequency 50.00 MHz
  ahbjtag0  Cobham Gaisler  JTAG Debug Link
            AHB Master 3
  apbmst0   Cobham Gaisler  AHB/APB Bridge
            AHB: 80000000 - 80100000
  dsu0      Cobham Gaisler  LEON3 Debug Support Unit
            AHB: 90000000 - A0000000
            CPU0:  win 8, hwbp 2, itrace 64, lddel 1
                   stack pointer 0x4001fff0
                   icache 1 * 1 kB, 16 B/line
                   dcache 1 * 1 kB, 16 B/line
  adev5     Cobham Gaisler  Generic AHB ROM
            AHB: 00000000 - 00100000
  ahbram0   Cobham Gaisler  Single-port AHB SRAM module
            AHB: 40000000 - 40100000
            Static RAM: 128 kB @ 0x40000000
  uart0     Cobham Gaisler  Generic UART
            APB: 80000100 - 80000200
            IRQ: 2
            Baudrate 38343, FIFO debug mode
  irqmp0    Cobham Gaisler  Multi-processor Interrupt Ctrl.
            APB: 80000200 - 80000300
  gpio0     Cobham Gaisler  General Purpose I/O port
            APB: 80000500 - 80000600
  gptimer0  Cobham Gaisler  Modular Timer Unit
            APB: 80000600 - 80000700
            IRQ: 8
            32-bit scalar, 5 * 32-bit timers, divisor 50
  adev11    Various contributions  Unknown device
            APB: 80013000 - 80014000
  adev12    Various contributions  Unknown device
            APB: 80014000 - 80015000
