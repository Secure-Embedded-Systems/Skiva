#!/usr/bin/perl

use strict;
use warnings;
use v5.14;

use File::Path qw( make_path remove_tree );
use File::Copy;

use FindBin;
chdir "$FindBin::Bin/..";

my $out_dir = 'asm-implems';
mkdir $out_dir unless -d $out_dir;

for my $ti (1, 2, 4) {
    for my $fd (1, 2, 4) {
        for my $pipeline ('', 'pipelined') {
            my $opt_pipeline = $pipeline ? '-D PIPELINED' : '';
            my $sizes = `sparc-gaisler-elf-gcc -mcpu=leon3 -mno-fpu -Wno-unused-function -Wall -Wextra -IFPGA-API/include -Iarch -O3 -D CST_RAND -D TI=$ti -D FD=$fd -D COMPACT $opt_pipeline aes/aes.c aes/bs.c -S`;
            my $Rt = $pipeline ? 2 : 1;
            my $dir = "$out_dir/bitsliceRt${Rt}Rs${fd}D${ti}/";
            make_path $dir unless -d $dir;
            move "aes.s", "$dir/aes.s";
            move "bs.s",  "$dir/bs.s";
        }
    }
}
