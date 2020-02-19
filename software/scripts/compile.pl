#!/usr/bin/perl

use strict;
use warnings;
use File::Copy;

use FindBin;

chdir "$FindBin::Bin/..";

mkdir 'bin' unless -d 'bin';

# WARNING: set to empty string if you want to test correctness rather
# than performances.
my $cheaty_custom = "-D CHEATY_CUSTOM";

for my $ti (1, 2, 4) {
    for my $fd (1, 2, 4) {
        for my $implem (qw(COMPACT UNROLLED)) {
            next if $implem eq 'UNROLLED';
            for my $no_custom_instr ('NO_CUSTOM_INSTR', '') {
                my $custom_opt = $no_custom_instr ? '-D NO_CUSTOM_INSTR' : '';
                for my $opti (qw(Os O3)) {
                    next if $opti eq 'Os';
                    for my $pipeline ('PIPELINED', '') {
                        for my $gcc_support ('GCCSUP', '') {
                            next if $gcc_support eq 'GCCSUP';
                            my $implem_name = "$implem-$ti-$fd-$opti" .
                                ($no_custom_instr ? '-NOCUSTOM'  : '') .
                                ($gcc_support ? '-GCCSUP' : '') .
                                ($pipeline ? "-$pipeline" : "");
                            my $pipeline_opt = $pipeline ? '-D PIPELINED' : '';
                            my $gcc_support = $gcc_support ? '-D GCC_SUPPORT' : '';
                            system "make clean -C aes";
                            system "make OPTI_FLAG='-$opti $cheaty_custom $gcc_support' TI='$ti' FD='$fd' IMPLEM='-D $implem' CUSTOM_INSTR='$custom_opt' PIPELINED='$pipeline_opt' IMPLEM_NAME='$implem_name' -C aes";
                            move 'aes/main', "bin/$implem_name";
                        }
                    }
                }
            }
        }
    }
}
