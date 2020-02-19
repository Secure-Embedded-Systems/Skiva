#!/usr/bin/perl

use strict;
use warnings;
use v5.14;
use autodie;

use FindBin;
chdir "$FindBin::Bin/../aes";

use Crypt::Mode::ECB;

my $key_char   = join "", map { sprintf "%02x", rand 256 } 0 .. 15;
my $plain_char = join "", map { join "", map { sprintf "%02x", rand 256 } 0 .. 15 } 0 .. 31;

my $key   = pack 'H*', $key_char;
my $plain = pack 'H*', $plain_char;

my $m = Crypt::Mode::ECB->new('AES',1);
my $cipher = $m->encrypt($plain, $key);

my $cipher_char = unpack 'H*', $cipher;

open my $FH, '>', 'faults_inputs.h';
printf $FH "unsigned char key[16] = {\n%s };\n", join ", ", map { sprintf "0x%s", $_ } $key_char =~ /../g;
printf $FH "unsigned char input[16*32] = {\n%s };\n", join ",\n", map { join ", ", map { sprintf "0x%s", $_ } $_ =~ /../g} $plain_char =~ /.{32}/g;
printf $FH "unsigned char output_ref[16*32] = {\n%s };\n", join ",\n", map { join ", ", map { sprintf "0x%s", $_ } $_ =~ /../g} ($cipher_char =~ /.{32}/g)[0..31];
