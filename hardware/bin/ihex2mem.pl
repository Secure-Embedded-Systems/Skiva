# This file generates a Verilog and testbench code for
# a circuit that finds the maximum of N elements each has 
# a width of k-bit.
#
# to run this perl file just write 
# perl ihex_file_name_without_extension 
#################################################
use POSIX;
$filename = $ARGV[0];
$infile = $filename."\.ihex";
$outfile = $filename."\.mem";
$outfile0 = $filename."0\.mem";
$outfile1 = $filename."1\.mem";
$outfile2 = $filename."2\.mem";
$outfile3 = $filename."3\.mem";
open INFILE, "< $infile"; # open file FX with a name of maxNk.v.v and use it for writing
open OUTFILE, "> $outfile"; # open file FX with a name of maxNk.v.v and use it for writing
open OUTFILE3, "> $outfile3"; # open file FX with a name of maxNk.v.v and use it for writing
open OUTFILE2, "> $outfile2"; # open file FX with a name of maxNk.v.v and use it for writing
open OUTFILE1, "> $outfile1"; # open file FX with a name of maxNk.v.v and use it for writing
open OUTFILE0, "> $outfile0"; # open file FX with a name of maxNk.v.v and use it for writing
#print $infile." ".$outfile."\n";

my $line_ctr = 0;
my $base_addr;


print OUTFILE "\/\/ systest data file\n";
print OUTFILE0 "\/\/ systest data file\n";
print OUTFILE2 "\/\/ systest data file\n";
print OUTFILE3 "\/\/ systest data file\n";
print OUTFILE4 "\/\/ systest data file\n";
print OUTFILE "\/\/ format=hex addressradix=h dataradix=h version=1\.0 wordsperline=4\n";
print OUTFILE0 "\/\/ format=hex addressradix=h dataradix=h version=1\.0 wordsperline=4\n";
print OUTFILE1 "\/\/ format=hex addressradix=h dataradix=h version=1\.0 wordsperline=4\n";
print OUTFILE2 "\/\/ format=hex addressradix=h dataradix=h version=1\.0 wordsperline=4\n";
print OUTFILE3 "\/\/ format=hex addressradix=h dataradix=h version=1\.0 wordsperline=4\n";
while(my $line = <INFILE>) {
	if ($line =~ ":02([0-9,A-F]{4})044([0-9,A-F]{3}).*"){
		$base_addr = '0'.$2;
	} elsif ($line =~ ":10([0-9,A-F]{3})([0-9,A-F]{1})00([0-9,A-F]{2})([0-9,A-F]{2})([0-9,A-F]{2})([0-9,A-F]{2})([0-9,A-F]{2})([0-9,A-F]{2})([0-9,A-F]{2})([0-9,A-F]{2})([0-9,A-F]{2})([0-9,A-F]{2})([0-9,A-F]{2})([0-9,A-F]{2})([0-9,A-F]{2})([0-9,A-F]{2})([0-9,A-F]{2})([0-9,A-F]{2}).*") {
		chomp($line);
		print OUTFILE "\@".$base_addr.$1."0 ".$3." ".$4." ".$5." ".$6."\n";
		print OUTFILE "\@".$base_addr.$1."4 ".$7." ".$8." ".$9." ".$10."\n";
		print OUTFILE "\@".$base_addr.$1."8 ".$11." ".$12." ".$13." ".$14."\n";
		print OUTFILE "\@".$base_addr.$1."C ".$15." ".$16." ".$17." ".$18."\n";
		
		$address = $1.$2;
		$address = hex($address);
		$address = $address/4;
		$address = sprintf("%08x", $address);
		#print "0x".$1.$2." ".$address;
		#print "\n";
		print OUTFILE3 "\@".$address." ".$3." ".$7." ".$11." ".$15."\n";
		print OUTFILE2 "\@".$address." ".$4." ".$8." ".$12." ".$16."\n";
		print OUTFILE1 "\@".$address." ".$5." ".$9." ".$13." ".$17."\n";
		print OUTFILE0 "\@".$address." ".$6." ".$10." ".$14." ".$18."\n";
		
	}
}
close(OUTFILE);
close(OUTFILE1);
close(OUTFILE2);
close(OUTFILE3);
close(OUTFILE4);





