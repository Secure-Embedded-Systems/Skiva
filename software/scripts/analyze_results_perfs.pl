#!/usr/bin/perl

use strict;
use warnings;
use v5.14;
use autodie qw( open close );
use Data::Printer;

use FindBin;
chdir "$FindBin::Bin/..";

mkdir 'gdb' unless -d 'gdb';

my $perf_file = 'out_perfs.txt';

open my $FH_PERFS, '<', $perf_file;
1 while <$FH_PERFS>; # Skipping to the end of the file

open my $FH_BIN, '<', 'bin/bin_list.txt';

my %perfs;

while (my $bin = <$FH_BIN>) {
    chomp $bin;
    my $bin_name = $bin =~ s{.*bin/}{}r;
    open my $FPOUT, '>', "gdb/perfs_$bin_name.txt";
    say $FPOUT "target extended-remote :2222
load
run
quit";

    system "sparc-gaisler-elf-gdb -x gdb/perfs_$bin_name.txt $bin";

    my $perfs = read_end_file($FH_PERFS);

    my $Rt = $bin =~ /PIPELINED/ ? 2 : 1;
    my ($implem, $ti, $fd, $details) = $bin_name =~ /(.*-(\d+)-(\d+)-O3(.*))/;
    my ($full) = $perfs =~ /bench_full: (\w+)/;
    my ($primitive) = $perfs =~ /primitive: (\w+)/;
    $full = int( hex($full) / 4096);
    $primitive = int( hex($primitive) / 10 / 16 / 32 * $fd * $ti * $Rt);

    $perfs{"$Rt-$fd-$ti"} = { full => $full, primitive => $primitive };
}

mkdir "results" unless -d "results";
open my $FPOUT, '>', 'results/general_perfs.tex';
my %to_str = ( 1 => 'One', 2 => 'Two', 4 => 'Four' );

for my $Rt (1, 2) {
    for my $ti (1, 2, 4) {
        for my $fd (1, 2, 4) {
            printf $FPOUT "\\newcommand{\\PerfsRt%sD%sRs%s}{%d}\n",
                $to_str{$Rt}, $to_str{$ti}, $to_str{$fd},
                $perfs{"$Rt-$fd-$ti"}->{full};
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
