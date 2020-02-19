Software side of SKIVA
===

## Terminology

The following terms come back in the code:

 - `TI`: the number of shares used by our masking scheme (`D` in our
   paper).
   
 - `FD`: the number of redundant slices used (`Rs` in our paper).
 
 - `PIPELINED`: if this macro is defined, the implementation with
   temporal redundancy using piplining is used (`Rt=2` in our paper).

## Organization

This folder contains the software used to interact with SKIVA,
organized in the following way:

 - `patches` contains a patch for `bcc` to assemble files containing
   SKIVA custom instructions.
   
 - `FPGA-API` contains a library to manipulate our target board (for
   instance, to use the timer).

 - `arch` contains header files providing macros to use SKIVA
   instructions, as well as software implementations of SKIVA
   instructions (in order to try out SKIVA codes on regular CPUs).
   
 - `aes` contains the source code of our AES implementations.
 
 - `scripts` contains scripts used to compile and evaluate our AES
   implementations.


Each folder contains its own Readme describing its content (except
`FPGA-API`). 


## Getting started

If you are just looking to compile and run our AES,
[aes/Readme](aes/Readme.md) is the place to start. In particular, go
into the `aes` folder, and run:

    make TI=<number of shares> FD=<number of redundant slices> PIPELINED="-D PIPELINED"
    
Where `PIPELNED="-D PIPELINED"` means temporal redundancy of 2
(Rt=2). It can be replaced by `PIPELINED=""` to disable temporal
redundancy (Rt=1). 

This will generate a binary called `main` which can be loaded onto the
FPGA and ran.
