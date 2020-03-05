Hardware design files of Skiva 
===

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

