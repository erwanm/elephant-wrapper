#!/usr/bin/perl

# EM Sept 17
#
#


use strict;
use warnings;
use Carp;
use Getopt::Std;
#use Data::Dumper;

binmode(STDOUT, ":utf8");

my $progname = "iob-fix-missing-b.pl";

my $bLabel ="B";
my $iLabel ="I";
my $oLabel ="O";
my $iobCol =2;

sub usage {
	my $fh = shift;
	$fh = *STDOUT if (!defined $fh);
	print $fh "\n"; 
	print $fh "Usage: $progname [options] <iob input file>  <iob output file>\n";
	print $fh "\n";
	print $fh "    Replaces Inside labels located after Outside labels with Begin labels.\n";
 	print $fh "\n";
 	print $fh "  Options:\n";
	print $fh "    -h print this help message.\n";
	print $fh "    -c <IOB column> default: $iobCol.\n";
	print $fh "    -b <B label> to use if label is not B.\n";
	print $fh "    -i <I label> to use if label is not I.\n";
	print $fh "    -o <O label> to use if label is not O.\n";
 	print $fh "\n";
}




# PARSING OPTIONS
my %opt;
getopts('hB:I:O:c:', \%opt ) or  ( print STDERR "Error in options" &&  usage(*STDERR) && exit 1);
usage(*STDOUT) && exit 0 if $opt{h};
print STDERR "2 arguments expected, but ".scalar(@ARGV)." found: ".join(" ; ", @ARGV)  && usage(*STDERR) && exit 1 if (scalar(@ARGV) != 2);

my $inputFile =  $ARGV[0];
my $outputFile =  $ARGV[1];

$bLabel =$opt{B} if (defined($opt{B}));
$iLabel =$opt{I} if (defined($opt{I}));
$oLabel =$opt{O} if (defined($opt{O}));

$iobCol=$opt{c} if (defined($opt{c}));
$iobCol--;

my $nb=0;
my $lineNo=1;
my $outside=1;

open(F, "<:encoding(utf-8)", $inputFile) or die "Cannot open '$inputFile'";
open(OUT, ">:encoding(utf-8)", $outputFile) or die "Cannot open '$outputFile' for writing";
while (<F>) {
    chomp;
    my @cols=split;
    my $iob = $cols[$iobCol];
    if ($iob eq $bLabel) {
	$outside=0;
    } elsif ($iob eq $iLabel) {
	if ($outside) {
	    $iob=$bLabel ;
	    $nb++;
	}
	$outside=0;
    } elsif ($iob eq $oLabel) {
	$outside=1;
    } else {
	die "Error: not an IOB label line $lineNo, column ".($iobCol+1).": '$iob'";
    }
    print OUT "$iob\n";
    $lineNo++;
}
close(F);
close(OUT);
$lineNo--;
print STDERR "Info: read $lineNo lines, replace $nb I labels with B labels.\n";

