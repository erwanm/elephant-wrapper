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

my $progname = "split-conllu-sentences.pl";

    
sub usage {
	my $fh = shift;
	$fh = *STDOUT if (!defined $fh);
	print $fh "\n"; 
	print $fh "Usage: $progname [options] <N> <conllu file>\n";
	print $fh "\n";
	print $fh "   Splits a conllu file (one line by token, at least one empty line between sentences)\n";
	print $fh "   into N parts, each containing approximately the\n";
 	print $fh "   same number of sentences.\n";
 	print $fh "   The output files are named <output prefix><index><output suffix>, where\n";
 	print $fh "   <output suffix> is empty by default (see options -b and -a).\n";
 	print $fh "\n";
 	print $fh "  Options:\n";
	print $fh "    -h print this help message.\n";
	print $fh "    -s shuffle sentences. Default: split using contiguous sets of sentences. NOT IMPLEMENTED YET\n";
	print $fh "    -b <output prefix> output filename starts with this (default: input filename dot).\n";
	print $fh "       Remark: the prefix can include a directory path, provided this path already exists.\n";
	print $fh "    -a <output suffix> output filename ends with this (default: empty string).\n";
 	print $fh "\n";
}




# PARSING OPTIONS
my %opt;
getopts('hsb:a:', \%opt ) or  ( print STDERR "Error in options" &&  usage(*STDERR) && exit 1);
usage(*STDOUT) && exit 0 if $opt{h};
print STDERR "2 arguments expected, but ".scalar(@ARGV)." found: ".join(" ; ", @ARGV)  && usage(*STDERR) && exit 1 if (scalar(@ARGV) != 2);

my $N = $ARGV[0];
my $inputFile =  $ARGV[1];

die "Error: option -r not implemented yet!" if (defined($opt{r}));

my $outputPrefix = (defined($opt{b})) ? $opt{b} : $inputFile.".";
my $outputSuffix = (defined($opt{a})) ? $opt{a} : "";


my @corpus;
my $sent;

open(F, "<:encoding(utf-8)", $inputFile) or die "Cannot open '$inputFile'";
while (<F>) {
    chomp;
    if  (m/./) {
	chomp;
	push(@$sent, $_);
    } else {
	if (scalar(@$sent) >0) {
	    push(@corpus, $sent);
	    $sent = [];
	}
    }
}
if (scalar(@$sent) >0) { # last sentence?
    push(@corpus, $sent);
    $sent = [];
}
close(F);

my $nbByBin =  scalar(@corpus) / $N; # potentially decimal number

if ($nbByBin >= 1) {
    print "Info: ".scalar(@corpus)." sentences found / $N = $nbByBin sentences by bin in average.\n";
} else {
    die "Error: corpus '$inputFile' contains only ".scalar(@corpus)." sentences, cannot split into $N parts.";
}

my $maxDigit = length($N -1);

my $currentBin = 0;
my $f = $outputPrefix.sprintf("%0${maxDigit}d", $currentBin).$outputSuffix;
open(OUT, ">:encoding(utf-8)", $f) or die "Cannot open '$f'";

for (my $i=0; $i<scalar(@corpus); $i++) {
    if ($i >= $currentBin *  $nbByBin + $nbByBin) {
	$currentBin++;
	close(OUT);
	$f = $outputPrefix.sprintf("%0${maxDigit}d", $currentBin).$outputSuffix;
	open(OUT, ">:encoding(utf-8)", $f) or die "Cannot open '$f'";
    }
    my $sent = $corpus[$i];
    foreach my $line (@$sent) {
	print OUT $line."\n";
    }
    print OUT "\n";
}
close(OUT);

