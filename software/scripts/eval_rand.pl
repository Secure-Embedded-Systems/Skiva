#!/usr/bin/perl

use strict;
use warnings;
use v5.14;
use autodie qw( open close );

use Cwd;
use FindBin;
chdir "$FindBin::Bin/..";

mkdir 'gdb' unless -d 'gdb';
mkdir 'bin' unless -d 'bin';
mkdir 'results' unless -d 'results';

my $perf_file = 'out_perfs.txt';

open my $FH_PERFS, '<', $perf_file;
1 while <$FH_PERFS>; # Skipping to the end of the file

open my $FP_OUT, '>', 'results/rng_impact.tex';

my %num = ( 1 => 'One', 2 => 'Two', 4 => 'Four' );

for my $Rt (1, 2) {
    my $pipeline     = $Rt == 2 ? '-PIPELINED' : '';
    my $pipeline_opt = $Rt == 2 ? '-D PIPELINED' : '';
    for my $ti (2, 4) {
        for my $fd (1, 2, 4) {
            for (my $rand = 10; $rand < 200; $rand += 10) {
                my $rand_div_10 = $rand / 10;
                system qq{sparc-gaisler-elf-gcc -mcpu=leon3 -mno-fpu -Wall -Wextra -Wno-unused-function -Iarch -IFPGA-API/include -O3 -D CHEATY_CUSTOM -D TI=$ti -D FD=$fd -D COMPACT $pipeline_opt -D COPROC_RAND -D RANDOM_DELAY=$rand_div_10 -D IMPLEM_NAME='"COMPACT-$ti-$fd-O3-RANDDELAY$rand$pipeline"' aes/aes.c aes/bs.c aes/key_sched.c aes/main.c aes/fame_lib.c -o bin/COMPACT-$ti-$fd-O3$pipeline-RANDDELAY$rand -LFPGA-API/lib -lfame};
                my $bin = getcwd() . "/bin/COMPACT-$ti-$fd-O3$pipeline-RANDDELAY$rand";

                my $bin_name = $bin =~ s{.*bin/}{}r;
                open my $FPOUT, '>', "gdb/rand_$bin_name.txt";
                say $FPOUT "target extended-remote :2222
load
run
quit";

                system "sparc-gaisler-elf-gdb -q -x gdb/rand_$bin_name.txt $bin";

                my $perfs = read_end_file($FH_PERFS);

                my ($full)      = $perfs  =~ /bench_full: (\w+)/;
                my ($waiting)   = $perfs  =~ /waiting: (\w+)/;
                my $delay = $rand;


                my $val = sprintf "%.2f", (hex($full) + hex($waiting)) / hex($full);

                next if $val < 1.015;

                $delay += 10 if $val < 1.03;
                say $FP_OUT "\\newcommand{\\RngLimiationRt$num{$Rt}Rs$num{$fd}D$num{$ti}}{$delay}";
                last;
            }
        }
    }
}

sub read_end_file {
    my $fh = shift;

    my $offset = tell $fh;
    my $prev   = $offset;
    local $/;
    my $read;
    while ($prev == $offset) {
        $read = <$fh>;
        $offset = tell $fh;
    }
    return $read;
}
