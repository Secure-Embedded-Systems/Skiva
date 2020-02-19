#!/usr/bin/perl

use strict;
use warnings;
use v5.14;
use autodie qw( open close );

use Fcntl qw(:seek);
use Time::Out qw(timeout);

use FindBin;
chdir "$FindBin::Bin/..";

my $out_file = 'out';

undef $/;

mkdir 'gdb' unless -d 'gdb';
mkdir 'bin' unless -d 'bin';
mkdir 'results' unless -d 'results';


my %bin = (
    'bin/COMPACT-PIPELINED-1-4-Os' => q{sparc-gaisler-elf-gcc -mcpu=leon3 -mno-fpu -Wall -Wextra -Wno-unused-function -Iarch -IFPGA-API/include -D CST_RAND -Os -D TI=1 -D FD=4 -D COMPACT -D PIPELINED -D IMPLEM_NAME='"COMPACT-PIPELINED-1-4-Os"' aes/aes.c aes/bs.c aes/key_sched.c aes/main_faults.c aes/fame_lib.c -o bin/COMPACT-PIPELINED-1-4-Os},
    'bin/COMPACT-1-4-Os' => q{sparc-gaisler-elf-gcc -mcpu=leon3 -mno-fpu -Wall -Wextra -Wno-unused-function -Iarch -IFPGA-API/include -D CST_RAND -Os -D TI=1 -D FD=4 -D COMPACT -D IMPLEM_NAME='"COMPACT-1-4-Os"' aes/aes.c aes/bs.c aes/key_sched.c aes/main_faults.c aes/fame_lib.c -o bin/COMPACT-1-4-Os}
    );


my $timeout = 60; # seconds
my $NO_LOOP = 1; # don't try to fault every iteration of loops
my $MAX_LOOP = 10; # don't loop more than 3 times
my $NB_RUNS = 100; # How many differents inputs to test

open my $FP_IN, '<', $out_file;
<$FP_IN>; # Go to end of $FP_IN


for my $run_nb (1 .. $NB_RUNS) {

    system './scripts/gen_aes_inputs.pl';

    for my $binary (keys %bin) {
        system $bin{$binary};

        my ($bin_name) = $binary =~ /([^\/]+)$/;
        open my $FP_OUT, '>>', "results/faults_res_${bin_name}.txt";
        printf $FP_OUT ( ('*'x30) . " Rand input %2d " . ('*'x30) . "\n", $run_nb);


        for my $fun (qw(AES_unprotected AES_protected SubBytes_single__ SubBytes__ ShiftRows__ MixColumn__ AddRoundKey__ round_compact lastround_compact)) {
            my ($start, $end);
            
            # Compute start and end address of AES_protected
            {
                system "sparc-gaisler-elf-objdump -d $binary > /tmp/faults_binary.txt";
                open my $FH, '<', "/tmp/faults_binary.txt";
                local $/ = "\n\n";
                while (<$FH>) {
                    next unless /<$fun>:/;
                    ($start) = /\n4000(\S+?):/;
                    ($end)   = /4000(\S+?):.*\s*$/;
                    last;
                }
                ($start, $end) = map { hex } map { $_ // "" } $start, $end;
            }
            next unless $start && $end;

            my $offset = tell $FP_IN;

            for (my $bp = $start; $bp <= $end; $bp += 4) {
                next unless $bp % 4 == 0;
                my $break = sprintf "0x4000%x", $bp;
                my $next  = sprintf "0x4000%x", $bp + 4;

                my $gdb_in = "gdb/fault_$bp.txt";

                my $prev_count = -1;
                for (my $loop_cnt = 0; $loop_cnt < $MAX_LOOP; $loop_cnt++) {
                    open my $FH_GDB, '>', $gdb_in;

                    my $cont = ("cont\n" x $loop_cnt) || "";

                    say $FH_GDB "target extended-remote :2222
load
break *$break
run
" . $cont . 
"del 1
jump *$next
cont
quit";
                    
                    my $gdb_output;
                    timeout $timeout => sub {
                        $gdb_output = `sparc-gaisler-elf-gdb -x $gdb_in $binary`;
                    };
                    if ($@) {
                        say $FP_OUT "$fun:$break [$loop_cnt]: timeout";
                        system "killall sparc-gaisler-elf-gdb";
                        read_end_file($FP_IN);
                        last;
                    }

                    timeout 3 => sub {
                        $_ = read_end_file($FP_IN);
                    };
                    if ($@) {
                        say $FP_OUT "$fun:$break [$loop_cnt]: no output to read...";
                        last;
                    }
                    
                    if (/Fault/) {
                        # Fault detected
                        print "$fun:$break [$loop_cnt]: OK (detected)";
                        print $FP_OUT "$fun:$break [$loop_cnt]: OK (detected)";
                        if (/AES seems correct/) {
                            # AES correct despite fault
                            say " (no impact)";
                            say $FP_OUT " (no impact)";
                        } else {
                            say "";
                            say $FP_OUT "";
                        }
                    } elsif (/Error/) {
                        # /Error/ but not /Fault/
                        say  "$fun:$break [$loop_cnt]: error (Undetected fault)";
                        say $FP_OUT "$fun:$break [$loop_cnt]: error (Undetected fault)";
                    } elsif (/AES seems correct/) {
                        # No /Fault/, no /Error/
                        say "$fun:$break [$loop_cnt]: OK (no effect)";
                        say $FP_OUT "$fun:$break [$loop_cnt]: OK (no effect)";
                    } else {
                        # No /Fault/, no /Error/, but no /AES seems correct/
                        say "$fun:$break [$loop_cnt]: OK (crashed)";
                        say $FP_OUT "$fun:$break [$loop_cnt]: OK (crashed)";
                    }
                    
                    my $new_count = () = $gdb_output =~ /Breakpoint/g;
                    last if $new_count == $prev_count;
                    $prev_count = $new_count;

                    last if $NO_LOOP;
                }

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
