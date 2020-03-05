# Design Directory for port of Skiva on  ALTERA DE2-115 FPGA board

Top Level file is LEON3_DE2115.v
Synthesis can be triggered using command "make quartus" 

## Pin Mapping

| Skiva pin     | Function                               | Sakura-G pin     |
|---------------|----------------------------------------|------------------|
| btnCpuResetn  | Global Reset                           | KEY3             |
| clk           | Internal input clock                   | CLOCK_50         |
| RsRx          | AHBUART receive                        |             |
| RsTx          | AHBUART transmit                       |             |
| rxd1          | APBUART receive                        |             |
| txd1          | APBUART transmit                       |             |
| gpio[0]       | GPIO                                   | LEDR0, GPIO0           |
| gpio[1]       | GPIO                                   | LEDR1, GPIO1      |
| gpio[2]       | GPIO                                   | LEDR2, GPIO2      |
| gpio[3]       | GPIO                                   | LEDR3, GPIO3      |
| gpio[4]       | GPIO                                   | LEDR4, GPIO4      |
| gpio[5]       | GPIO                                   | LEDR5, GPIO5      |
| gpio[6]       | GPIO                                   | LEDR6, GPIO6      |
| gpio[7]       | GPIO                                   | LEDR07, GPIO7     |


