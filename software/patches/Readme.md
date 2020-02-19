Patching BCC
===

To support the SKIVA instruction set extension (andc8, andc16, etc.),
apply the patch given in

    bcc_opcodes.patch

to the source of BCC, which can be obtained at:

    https://www.gaisler.com/anonftp/bcc2/src/

Then compile.

This has been tested (and approved) with:

    https://www.gaisler.com/anonftp/bcc2/src/bcc-2.0.4-src.tar.bz2
