Hardware design files of Skiva 
===

## Organization 
This repository includes hardware design files for the Skiva project, building upon the FAME-v2 specific modified version of GRLIB library of Cobham Gaisler. The repository adopts the file hierarchy of the original GRLIB distribution:
* bin:			various scripts and tool support files
* designs:		template design files for FPGA prototyping boards
* lib: 			VHDL libraries

## Getting started

To get the programmable file for Sakura-G FPGA board, run the following commands:
```sh
$ cd designs/leon3-sakura/
$ make ise
```
The output file is leon3mp.bit and can be programmed on the main FPGA on Sakura-G board.

To get the programmable file for DE2 FPGA board, run the following commands:
```sh
$ cd designs/leon3-terasic-de2-115/
$ make quartus
```
The generated programmable files LEON3_DE2115_quartus.qpf and LEON3_DE2115_quartus.qsf can be used to program the DE2 board.

## References

[1] P. Kiaei, D. Mercadier, P.-E. Dagand, K. Heydemann, and P. Schaumont, “Custom instruction support for modular defense against side-channel and fault attacks,” in Constructive Side-Channel Analysis and Secure Design - 11th International Workshop, COSADE 2020, Lugano,Switzerland, April 1-3, 2020, Proceedings. 
Preprint available at https://eprint.iacr.org/2019/756.pdf
