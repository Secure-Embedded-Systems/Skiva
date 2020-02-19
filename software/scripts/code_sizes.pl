#!/usr/bin/perl

use strict;
use warnings;
use v5.14;

use FindBin;

chdir "$FindBin::Bin/../aes";


my %res;
for my $ti (1, 2, 4) {
    for my $fd (1, 2, 4) {
        for my $custom ('hard', 'soft') {
            for my $pipeline ('', 'pipelined') {
                my $opt_custom   = $custom eq 'hard' ? '' : '-D NO_CUSTOM_INSTR';
                my $opt_pipeline = $pipeline ? '-D PIPELINED' : '';
                my $sizes = `sparc-gaisler-elf-gcc -mcpu=leon3 -mno-fpu -Wno-unused-function -Wall -Wextra -I../FPGA-API/include -I../arch -O3 -D TI=$ti -D FD=$fd -D COMPACT $opt_custom $opt_pipeline aes.c bs.c -c && sparc-gaisler-elf-size aes.o bs.o`;
                my ($aes,$bs) = $sizes =~ /^\s*(\d+)/mg;
                $res{"$ti-$fd-$custom" . ($pipeline ? "-$pipeline" : "")} = [$aes,$bs];
                system "rm aes.o bs.o";
            }
        }
    }
}

chdir "..";
mkdir 'results' unless -d 'results';

open my $FP_OUT, '>', 'results/code_sizes.txt' or die $!;
for my $implem (sort keys %res) {
    say $FP_OUT "$implem @{$res{$implem}}";
}

open $FP_OUT, '>', 'results/code_sizes.tex';
printf $FP_OUT
"\\newcommand{\\CodesizeDOne}{%d}
\\newcommand{\\CodesizeDTwo}{%d}
\\newcommand{\\CodesizeDFour}{%d}
\\newcommand{\\CodesizeRatioDOneTwo}{%.1f}
\\newcommand{\\CodesizeRatioDOneFour}{%.1f}
\\newcommand{\\CodesizeRatioCustomRsFourDTwo}{%.1f}
\\newcommand{\\CodesizeRatioCustomRsFourDFour}{%.1f}",
    ($res{'1-4-hard'}[0]+$res{'1-4-hard'}[1]),
    ($res{'2-4-hard'}[0]+$res{'2-4-hard'}[1]),
    ($res{'4-4-hard'}[0]+$res{'4-4-hard'}[1]),
    ($res{'2-4-hard'}[0]+$res{'2-4-hard'}[1]) / ($res{'1-4-hard'}[0]+$res{'1-4-hard'}[1]),
    ($res{'4-4-hard'}[0]+$res{'4-4-hard'}[1]) / ($res{'1-4-hard'}[0]+$res{'1-4-hard'}[1]),
    ($res{'2-4-soft'}[0]+$res{'2-4-soft'}[1]) / ($res{'2-4-hard'}[0]+$res{'2-4-hard'}[1]),
    ($res{'4-4-soft'}[0]+$res{'4-4-soft'}[1]) / ($res{'4-4-hard'}[0]+$res{'4-4-hard'}[1]);
