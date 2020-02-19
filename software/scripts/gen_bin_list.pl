#!/usr/bin/perl

use strict;
use warnings;
use v5.14;

use Cwd;
use FindBin;
chdir "$FindBin::Bin/..";

my $PATH = getcwd;

mkdir 'bin' unless -d 'bin';

open my $FP_OUT, '>', 'bin/bin_list.txt' or die $!;

for my $implem ('-PIPELINED', '', '-GCCSUP', '-GCCSUP-PIPELINED', 
                '-NOCUSTOM', '-NOCUSTOM-PIPELINED') {
    next if $implem =~ /GCCSUP/ || $implem =~ /NOCUSTOM/;
    for my $ti (1, 2, 4) {
        for my $fd (1, 2, 4) {
            say $FP_OUT "$PATH/bin/COMPACT-$ti-$fd-O3$implem";
        }
    }
}
