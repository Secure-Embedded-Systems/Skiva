Hardware design files of Skiva 
===

## Organization 
This repository includes hardware design files for the Skiva project, building upon the FAME-v2 specific modified version of GRLIB library of Cobham Gaisler. The repository adopts the file hierarchy of the original GRLIB distribution:
* bin:			various scripts and tool support files
* boards:			support files for FPGA prototyping boards
* designs:		template designs
* lib: 			VHDL libraries

## Getting started
To get the programmable file for Sakura-G FPGA board:

```sh
$ cd designs/leon3-sakura/
$ make ise
```
