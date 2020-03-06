# Design Directory for port of Skiva on Sakura-G FPGA board

- Top Level file is leon3mp.vhd.
- Synthesis can be triggered by the command "make ise".
- The Skiva port on the SAKURA-G board requires an external clock connected to the J4 SMA connector.

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
