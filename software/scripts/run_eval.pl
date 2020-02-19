#!/usr/bin/perl

use strict;
use warnings;
use v5.14;

do './compile.pl';
do './code_sizes.pl';
do './gen_bin_list.pl';
do './analyze_results_perfs.pl';

do './compute_ratios.pl';

do './eval_rand.pl';

