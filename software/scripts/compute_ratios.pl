#!/usr/bin/perl

use strict;
use warnings;
use v5.14;
use autodie qw( open close );

use Cwd;
use FindBin;
chdir "$FindBin::Bin/..";

mkdir 'gdb' unless -d 'gdb';

my $perf_file = 'out_perfs.txt';

open my $FH_PERFS, '<', $perf_file;
1 while <$FH_PERFS>; # Skipping to the end of the file


my %perfs;

for my $Rt (1, 2) {
    for my $ti (1, 2, 4) {
        for my $fd (1, 2, 4) {
            for my $custom ('wcustom', 'nocustom') {
                my $bin_name = "COMPACT-$ti-$fd-O3" .
                    ($custom =~ /w/ ? '' : '-NOCUSTOM') .
                    ($Rt == 1 ? '' : '-PIPELINED');
                my $bin = getcwd() . "/bin/$bin_name";

                open my $FPOUT, '>', "gdb/perfs_$bin_name.txt";
                say $FPOUT "target extended-remote :2222
load
run
quit";

                system "sparc-gaisler-elf-gdb -q -x gdb/perfs_$bin_name.txt $bin";

                my $perfs = read_end_file($FH_PERFS);

                my ($full) = $perfs =~ /bench_full: (\w+)/;
                my ($primitive) = $perfs =~ /primitive: (\w+)/;

                $full = int( hex($full) / 4096);
                $primitive = int( hex($primitive) / 10 / 16 / 32 * $fd * $ti * $Rt);

                $perfs{$custom}->{$Rt}->{$ti}->{$fd} =
                    { full => $full, primitive => $primitive };
            }
        }
    }
}

mkdir 'results' unless -d 'results';

open my $FPOUT, '>', 'results/speedups_custom.tex';
my %to_str = ( 1 => 'One', 2 => 'Two', 4 => 'Four' );
for my $Rt (1, 2) {
    for my $ti (1, 2, 4) {
        for my $fd (1, 2, 4) {
            printf $FPOUT "\\newcommand{\\SpeedupCustomRt%sD%sRs%s}{%.2f}\n",
                $to_str{$Rt}, $to_str{$ti}, $to_str{$fd},
                $perfs{nocustom}->{$Rt}->{$ti}->{$fd}->{full} /
                $perfs{wcustom}->{$Rt}->{$ti}->{$fd}->{full};
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
