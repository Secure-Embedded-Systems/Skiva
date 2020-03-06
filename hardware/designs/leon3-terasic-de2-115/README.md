# Design Directory for port of Skiva on  ALTERA DE2-115 FPGA board

Top Level file is LEON3_DE2115.v
Synthesis can be triggered using command "make quartus" 

## Pin Mapping

| Skiva pin     | Function                               | Sakura-G pin     |
|---------------|----------------------------------------|------------------|
| btnCpuResetn  | Global Reset                           | KEY[3]           |
| clk           | Internal input clock                   | CLOCK_50         |
| RsRx          | AHBUART receive                        | GPIO[35]         |
| RsTx          | AHBUART transmit                       | GPIO[33]         |
| rxd1          | APBUART receive                        | GPIO[29]         |
| txd1          | APBUART transmit                       | GPIO[31]         |
| gpio[0]       | GPIO                                   | LEDR[0], GPIO[0] |
| gpio[1]       | GPIO                                   | LEDR[1], GPIO[1] |
| gpio[2]       | GPIO                                   | LEDR[2], GPIO[2] |
| gpio[3]       | GPIO                                   | LEDR[3], GPIO[3] |
| gpio[4]       | GPIO                                   | LEDR[4], GPIO[4] |
| gpio[5]       | GPIO                                   | LEDR[5], GPIO[5] |
| gpio[6]       | GPIO                                   | LEDR[6], GPIO[6] |
| gpio[7]       | GPIO                                   | LEDR0[7], GPIO[7]|


