# This file generates a Verilog and testbench code for
# a circuit that finds the maximum of N elements each has 
# a width of k-bit.
#
# to run this perl file just write 
# perl mem2mem ihex_file_name_without_extension 
#################################################
use POSIX;
$filename = $ARGV[0];
$infile0 = $filename."0\.mem";
$infile1 = $filename."1\.mem";
$infile2 = $filename."2\.mem";
$infile3 = $filename."3\.mem";

$outfile0 = $filename."0a\.mem";
$outfile1 = $filename."0b\.mem";
$outfile2 = $filename."0c\.mem";
$outfile3 = $filename."0d\.mem";
$outfile4 = $filename."1a\.mem";
$outfile5 = $filename."1b\.mem";
$outfile6 = $filename."1c\.mem";
$outfile7 = $filename."1d\.mem";
$outfile8 = $filename."2a\.mem";
$outfile9 = $filename."2b\.mem";
$outfile10 = $filename."2c\.mem";
$outfile11 = $filename."2d\.mem";
$outfile12 = $filename."3a\.mem";
$outfile13 = $filename."3b\.mem";
$outfile14 = $filename."3c\.mem";
$outfile15 = $filename."3d\.mem";

open INFILE3, "< $infile3"; # open file FX with a name of maxNk.v.v and use it for writing
open INFILE2, "< $infile2"; # open file FX with a name of maxNk.v.v and use it for writing
open INFILE1, "< $infile1"; # open file FX with a name of maxNk.v.v and use it for writing
open INFILE0, "< $infile0"; # open file FX with a name of maxNk.v.v and use it for writing

open OUTFILE0 , "> $outfile0 "; # open file FX with a name of maxNk.v.v and use it for writing
open OUTFILE1 , "> $outfile1 "; # open file FX with a name of maxNk.v.v and use it for writing
open OUTFILE2 , "> $outfile2 "; # open file FX with a name of maxNk.v.v and use it for writing
open OUTFILE3 , "> $outfile3 "; # open file FX with a name of maxNk.v.v and use it for writing
open OUTFILE4 , "> $outfile4 "; # open file FX with a name of maxNk.v.v and use it for writing
open OUTFILE5 , "> $outfile5 "; # open file FX with a name of maxNk.v.v and use it for writing
open OUTFILE6 , "> $outfile6 "; # open file FX with a name of maxNk.v.v and use it for writing
open OUTFILE7 , "> $outfile7 "; # open file FX with a name of maxNk.v.v and use it for writing
open OUTFILE8 , "> $outfile8 "; # open file FX with a name of maxNk.v.v and use it for writing
open OUTFILE9 , "> $outfile9 "; # open file FX with a name of maxNk.v.v and use it for writing
open OUTFILE10, "> $outfile10"; # open file FX with a name of maxNk.v.v and use it for writing
open OUTFILE11, "> $outfile11"; # open file FX with a name of maxNk.v.v and use it for writing
open OUTFILE12, "> $outfile12"; # open file FX with a name of maxNk.v.v and use it for writing
open OUTFILE13, "> $outfile13"; # open file FX with a name of maxNk.v.v and use it for writing
open OUTFILE14, "> $outfile14"; # open file FX with a name of maxNk.v.v and use it for writing
open OUTFILE15, "> $outfile15"; # open file FX with a name of maxNk.v.v and use it for writing
#print $infile." ".$outfile."\n";

my $line_ctr = 0;
my $base_addr;


print OUTFILE0  "\/\/ systest data file\n";
print OUTFILE1  "\/\/ systest data file\n";
print OUTFILE2  "\/\/ systest data file\n";
print OUTFILE3  "\/\/ systest data file\n";
print OUTFILE4  "\/\/ systest data file\n";
print OUTFILE5  "\/\/ systest data file\n";
print OUTFILE6  "\/\/ systest data file\n";
print OUTFILE7  "\/\/ systest data file\n";
print OUTFILE8  "\/\/ systest data file\n";
print OUTFILE9  "\/\/ systest data file\n";
print OUTFILE10 "\/\/ systest data file\n";
print OUTFILE11 "\/\/ systest data file\n";
print OUTFILE12 "\/\/ systest data file\n";
print OUTFILE13 "\/\/ systest data file\n";
print OUTFILE14 "\/\/ systest data file\n";
print OUTFILE15 "\/\/ systest data file\n";


print OUTFILE0  "\/\/ format=hex addressradix=h dataradix=h version=1\.0 wordsperline=4\n";
print OUTFILE1  "\/\/ format=hex addressradix=h dataradix=h version=1\.0 wordsperline=4\n";
print OUTFILE2  "\/\/ format=hex addressradix=h dataradix=h version=1\.0 wordsperline=4\n";
print OUTFILE3  "\/\/ format=hex addressradix=h dataradix=h version=1\.0 wordsperline=4\n";
print OUTFILE4  "\/\/ format=hex addressradix=h dataradix=h version=1\.0 wordsperline=4\n";
print OUTFILE5  "\/\/ format=hex addressradix=h dataradix=h version=1\.0 wordsperline=4\n";
print OUTFILE6  "\/\/ format=hex addressradix=h dataradix=h version=1\.0 wordsperline=4\n";
print OUTFILE7  "\/\/ format=hex addressradix=h dataradix=h version=1\.0 wordsperline=4\n";
print OUTFILE8  "\/\/ format=hex addressradix=h dataradix=h version=1\.0 wordsperline=4\n";
print OUTFILE9  "\/\/ format=hex addressradix=h dataradix=h version=1\.0 wordsperline=4\n";
print OUTFILE10 "\/\/ format=hex addressradix=h dataradix=h version=1\.0 wordsperline=4\n";
print OUTFILE11 "\/\/ format=hex addressradix=h dataradix=h version=1\.0 wordsperline=4\n";
print OUTFILE12 "\/\/ format=hex addressradix=h dataradix=h version=1\.0 wordsperline=4\n";
print OUTFILE13 "\/\/ format=hex addressradix=h dataradix=h version=1\.0 wordsperline=4\n";
print OUTFILE14 "\/\/ format=hex addressradix=h dataradix=h version=1\.0 wordsperline=4\n";
print OUTFILE15 "\/\/ format=hex addressradix=h dataradix=h version=1\.0 wordsperline=4\n";

while(my $line = <INFILE0>) {


	if ($line =~ "\@00000([0-9,A-F,a-f]{3}) .*"){
		chomp($line);
		print OUTFILE0 $line."\n";
	} elsif ($line =~ "\@00001([0-9,A-F,a-f]{3}) .*"){
		chomp($line);
		print OUTFILE0 $line."\n";
	} elsif ($line =~ "\@00002([0-9,A-F,a-f]{3})( .*)"){
		chomp($2);
		print OUTFILE1 "\@00000".$1. $2."\n";
	} elsif ($line =~ "\@00003([0-9,A-F,a-f]{3})( .*)"){
		chomp($2);
		print OUTFILE1 "\@00001".$1. $2."\n";
	} elsif ($line =~ "\@00004([0-9,A-F,a-f]{3})( .*)"){
		chomp($2);
		print OUTFILE2 "\@00000".$1. $2."\n";
	} elsif ($line =~ "\@00005([0-9,A-F,a-f]{3})( .*)"){
		chomp($2);
		print OUTFILE2 "\@00001".$1. $2."\n";
	} elsif ($line =~ "\@00006([0-9,A-F,a-f]{3})( .*)"){
		chomp($2);
		print OUTFILE3 "\@00000".$1. $2."\n";
	} elsif ($line =~ "\@00007([0-9,A-F,a-f]{3})( .*)"){
		chomp($2);
		print OUTFILE3 "\@00001".$1. $2."\n";
	}
}
close(INFILE0);
close(OUTFILE0);
close(OUTFILE1);
close(OUTFILE2);
close(OUTFILE3);

while(my $line = <INFILE1>) {


	if ($line =~ "\@00000([0-9,A-F,a-f]{3}) .*"){
		chomp($line);
		print OUTFILE4 $line."\n";
	} elsif ($line =~ "\@00001([0-9,A-F,a-f]{3}) .*"){
		chomp($line);
		print OUTFILE4 $line."\n";
	} elsif ($line =~ "\@00002([0-9,A-F,a-f]{3})( .*)"){
		chomp($2);
		print OUTFILE5 "\@00000".$1. $2."\n";
	} elsif ($line =~ "\@00003([0-9,A-F,a-f]{3})( .*)"){
		chomp($2);
		print OUTFILE5 "\@00001".$1. $2."\n";
	} elsif ($line =~ "\@00004([0-9,A-F,a-f]{3})( .*)"){
		chomp($2);
		print OUTFILE6 "\@00000".$1. $2."\n";
	} elsif ($line =~ "\@00005([0-9,A-F,a-f]{3})( .*)"){
		chomp($2);
		print OUTFILE6 "\@00001".$1. $2."\n";
	} elsif ($line =~ "\@00006([0-9,A-F,a-f]{3})( .*)"){
		chomp($2);
		print OUTFILE7 "\@00000".$1. $2."\n";
	} elsif ($line =~ "\@00007([0-9,A-F,a-f]{3})( .*)"){
		chomp($2);
		print OUTFILE7 "\@00001".$1. $2."\n";
	}
}
close(INFILE1);
close(OUTFILE4);
close(OUTFILE5);
close(OUTFILE6);
close(OUTFILE7);

while(my $line = <INFILE2>) {


	if ($line =~ "\@00000([0-9,A-F,a-f]{3}) .*"){
		chomp($line);
		print OUTFILE8 $line."\n";
	} elsif ($line =~ "\@00001([0-9,A-F,a-f]{3}) .*"){
		chomp($line);
		print OUTFILE8 $line."\n";
	} elsif ($line =~ "\@00002([0-9,A-F,a-f]{3})( .*)"){
		chomp($2);
		print OUTFILE9 "\@00000".$1. $2."\n";
	} elsif ($line =~ "\@00003([0-9,A-F,a-f]{3})( .*)"){
		chomp($2);
		print OUTFILE9 "\@00001".$1. $2."\n";
	} elsif ($line =~ "\@00004([0-9,A-F,a-f]{3})( .*)"){
		chomp($2);
		print OUTFILE10 "\@00000".$1. $2."\n";
	} elsif ($line =~ "\@00005([0-9,A-F,a-f]{3})( .*)"){
		chomp($2);
		print OUTFILE10 "\@00001".$1. $2."\n";
	} elsif ($line =~ "\@00006([0-9,A-F,a-f]{3})( .*)"){
		chomp($2);
		print OUTFILE11 "\@00000".$1. $2."\n";
	} elsif ($line =~ "\@00007([0-9,A-F,a-f]{3})( .*)"){
		chomp($2);
		print OUTFILE11 "\@00001".$1. $2."\n";
	}
}
close(INFILE2);
close(OUTFILE8);
close(OUTFILE9);
close(OUTFILE10);
close(OUTFILE11);

while(my $line = <INFILE3>) {


	if ($line =~ "\@00000([0-9,A-F,a-f]{3}) .*"){
		chomp($line);
		print OUTFILE12 $line."\n";
	} elsif ($line =~ "\@00001([0-9,A-F,a-f]{3}) .*"){
		chomp($line);
		print OUTFILE12 $line."\n";
	} elsif ($line =~ "\@00002([0-9,A-F,a-f]{3})( .*)"){
		chomp($2);
		print OUTFILE13 "\@00000".$1. $2."\n";
	} elsif ($line =~ "\@00003([0-9,A-F,a-f]{3})( .*)"){
		chomp($2);
		print OUTFILE13 "\@00001".$1. $2."\n";
	} elsif ($line =~ "\@00004([0-9,A-F,a-f]{3})( .*)"){
		chomp($2);
		print OUTFILE14 "\@00000".$1. $2."\n";
	} elsif ($line =~ "\@00005([0-9,A-F,a-f]{3})( .*)"){
		chomp($2);
		print OUTFILE14 "\@00001".$1. $2."\n";
	} elsif ($line =~ "\@00006([0-9,A-F,a-f]{3})( .*)"){
		chomp($2);
		print OUTFILE15 "\@00000".$1. $2."\n";
	} elsif ($line =~ "\@00007([0-9,A-F,a-f]{3})( .*)"){
		chomp($2);
		print OUTFILE15 "\@00001".$1. $2."\n";
	}
}
close(INFILE3);
close(OUTFILE12);
close(OUTFILE13);
close(OUTFILE14);
close(OUTFILE15);



