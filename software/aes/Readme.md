SKIVA AES implementation 
===
   
   
### Implementation organization
 

Our bitslice AES implementation is organized in the following way:

 - (not in this folder) The [`arch` folder](../arch) contains headers
   use by most of the files, related to custom instructions,
   randomness, masking implementation, and redundancy
   implementation. It contains its own Readme.

 - `bs.c` contains the functions to bitslice, mask, and duplicate the
   inputs. The only functions you should need are those declared in
   the header `bs.h`: `normal_to_bs` goes from an direct and
   unprotected input to a bitsliced and protected one, while
   `bs_to_normal` does the opposite transformation.
   
 - `key_sched.c` contains the key schedule for AES. The only function
   you should need is `key_sched`, declared in `key_sched.h`, which
   computes the subkeys of AES. Note that it does no
   bitslicing/masking/duplicattion, which should all be done afterward.

 - `aesround-compact.c` and `aesround-unrolled.c` are our
   implementations of a single round of the AES primitive. The first
   one uses loops (for instance to call the Sbox 16 times or to call
   MixColumn 4 times), while in the second one, all loops are
   unrolled, and all functions are inlined. The second one is arguably
   less vulnerable to control-faults, but it is much larger, and
   cannot fit on our FPGA when using Rs=4 and D=4. Furtheremore, since
   we protect against control-flow using a pipelining mechanisme
   (Rt=2), this is not an issue. Both those codes have been generated
   by Usuba from `aesround.ua`. The only functions you should need to
   call are `round__` which computes a round of AES, and
   `lastround__`, which computes the last round of AES.
   
 - `aes-inlined-unrolled.c` is a full bitslice AES implementation,
   where all loops are unrolled and all functions are inlined. Unlike
   `aesround-*.c` which provide functions to compute a single round of
   AES, it provides the function `aes_full` which computes a whole
   AES. Note that this implementation could be used outside of SKIVA
   altogether by just redefining the macros `XOR`, `AND` and
   `NOT`. For instance, a bitslice non-masked non-redundant
   implementation of AES can be obtained by defining:
   
   ```
   #define XOR(r,a,b) r = a ^ b
   #define AND(r,a,b) r = a & b
   #define NOT(r,a)   r = ~a
   ```
   
 - `aes-inlined-unrolled-partial.c` is the same as
   `aes-inlined-unrolled.c` excepts that the Sbox is not inlined. As a
   result, the code is about 4 times smaller, and the performances
   should be similar (depending on the architecture).
   
 - `aes.c` puts it all together:
     
     + `AES_protected` takes bitsliced-masked-duplicated data as input
       and computes a full AES using `round__` and `lastround__`
       (defined above), while adding our pipelined temporal redundancy
       scheme (Rt=2).
       
     + `AES_unprotected`takes bitsliced-masked-duplicated data as
       input and computes a full AES using `round__` and `lastround__`
       (defined above), without temporal redundancy (Rt=1). If
       `FULLY_UNROLLED` is defined, it instead does a single call to
       `FULL_AES__` from `full_aes.c`. Note that the name is slighly
       missleading: it is still protected against data faults and
       power attacks; just not against control faults.
       
     + `AES_wrapper` takes bitsliced-masked-duplicated subkeys, but a
       direct unprotected 128-bit plaintext and returns an unprotected
       128-bit ciphertext. It calls `normal_to_bs` (defined above) to
       protect the plaintext, then call `AES_protected` or
       `AES_unprotected` (defined above), and then unprotects it using
       `bs_to_normal` (defined above).
       
     + `AES_encrypt_data` takes an arbitray-length plaintext, and a
       key; both unprotected. It calls `key_sched` (defined above) and
       `normal_to_bs` (defined above) to compute and protect the
       subkeys. It then repeatedly calls `AES_wrapper` (defined above)
       to encrypt the whole plaintext.

 - `main.c` just serves a testing purpose: 
 
     + `test_AES_ref_input` runs `AES_encrypt_data` (defined above) on
       some known plaintexts, and checks if the resulting ciphertexts
       are as expected. This doesn't ensure that our implementation is
       correct, but tells us that it _seems_ correct.
       
     + `bench_full` benchmarks the number of cycles needed to encrypt
       unprotected data: key scheduling, masking, bitslicing,
       duplication, and AES are all taken into account.
       
     + `bench_primitive` benchmarks the number of cycles taken only by
       the AES primitive (ie, excluding bitslicing, masking,
       duplication and key schedule).

 - `main_faults.c` is used in our experimental fault injection
   tests. It contains a function similar to `test_AES_ref_input` from
   `main.c`, excepts that instead of always using the same
   inputs/outputs, it uses the inputs and outputs defined in
   `faults_inputs.h`. `fault_inputs.h` is generated using
   `../scripts/gen_aes_inputs.pl`.

   
 - `fame_lib.c` contains our own implementation of C's standard
   functions `memcpy` and `memcmp`, in order to reduce the amount of
   dependencies, and because it seems that when using some C standard
   functions, the size of the binaries grow too much.

### Macros


Various aspects of our implementations are controlled by defining (or
not) some macros (eg, masking order, redundancy level, pipelining,
source of randomness, architecture). Most of those macros are
explained in [../arch/Readme.md](../arch/Readme.md). The others are:

  - `IMPLEM_NAME`: a string that is printed by `main.c` when running
    benchmarks. This helps distinguishing between implementations when
    running multiple benchmarks. Defaults to `"main"`.
    
  - `COMPACT`: if defined, the compact (non-unrolled and non-inline)
    version of the AES round is used.
    
  - `FULLY_UNROLLED`: if defined, the fully unrolled and inlined
    version of the AES round is used. One of `FULLY_UNROLLED` and
    `COMPACT` _must_ be defined.
    

### Compiling

A [Makefile](Makefile) is given to compile a given implementation. For
instance, to compile our most protected version:

    make TI=4 FD=4 PIPELINED="-D PIPELINED"

And, to compile an unprotected version:

    make TI=1 FD=1 PIPELINED=""

The resulting binary will be called `main`. You can load it on the
FPGA (using _eg._ grmon) and run it.
