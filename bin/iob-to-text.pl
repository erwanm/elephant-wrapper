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

my $progname = "iob-output-to-text.pl";

my $bLabel ="B";
my $iLabel ="I";
my $oLabel ="O";
my $iobCol =2;
my $unicodeCol = 1;

sub usage {
	my $fh = shift;
	$fh = *STDOUT if (!defined $fh);
	print $fh "\n"; 
	print $fh "Usage: $progname [options] <iob input file>  <text output file>\n";
	print $fh "\n";
	print $fh "    Prints the tokenized text with tokens separated by spaces.\n";
 	print $fh "\n";
 	print $fh "  Options:\n";
	print $fh "    -h print this help message.\n";
	print $fh "    -c <IOB column> default: $iobCol.\n";
	print $fh "    -u <unicode value column> default: $unicodeCol.\n";
	print $fh "    -b <B label> to use if label is not B.\n";
	print $fh "    -i <I label> to use if label is not I.\n";
	print $fh "    -o <O label> to use if label is not O.\n";
	print $fh "    -n print the non-tokenized text instead, i.e. just convert\n";
	print $fh "       unicode points values to characters.\n";
 	print $fh "\n";
}




# PARSING OPTIONS
my %opt;
getopts('hB:I:O:c:n', \%opt ) or  ( print STDERR "Error in options" &&  usage(*STDERR) && exit 1);
usage(*STDOUT) && exit 0 if $opt{h};
print STDERR "2 arguments expected, but ".scalar(@ARGV)." found: ".join(" ; ", @ARGV)  && usage(*STDERR) && exit 1 if (scalar(@ARGV) != 2);

my $inputFile =  $ARGV[0];
my $outputFile =  $ARGV[1];

$bLabel =$opt{B} if (defined($opt{B}));
$iLabel =$opt{I} if (defined($opt{I}));
$oLabel =$opt{O} if (defined($opt{O}));

my $tokenize = (defined($opt{n})) ? 0 : 1 ;

$iobCol=$opt{c} if (defined($opt{c}));
$unicodeCol=$opt{u} if (defined($opt{u}));
$iobCol--;
$unicodeCol--;

my $lineNo=1;
my $token="";
my $first= 1;

open(F, "<:encoding(utf-8)", $inputFile) or die "Cannot open '$inputFile'";
open(OUT, ">:encoding(utf-8)", $outputFile) or die "Cannot open '$outputFile' for writing";
while (<F>) {
    chomp;
    my @cols=split;
    my $iob = $cols[$iobCol];
    my $unicode = $cols[$unicodeCol];
    if ($tokenize) {
	if ($iob eq $bLabel) {
	    print OUT " " if (!$first);
	    $first = 0;
	    print "$token" if (length($token)>0);
	    $token=chr($unicode);
	} elsif ($iob eq $iLabel) {
	    $token .= chr($unicode);
	} else {
	    die "Error: not an IOB label line $lineNo, column ".($iobCol+1).": '$iob'" if ($iob ne $oLabel);
	}
    } else {
	print OUT chr($unicode);
    }
    $lineNo++;
}
print " " if (!$first);
print "$token" if (length($token)>0);
close(F);
close(OUT);
$lineNo--;

