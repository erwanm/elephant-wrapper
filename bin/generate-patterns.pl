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

my $progname = "generate-patterns.pl";

my $outputSuffix=".pat";
my $ngramMaxSize=1;
my $useUnicodePoint=2;
my $useUnicodeCateg=2;
my $useElman=2;
    
sub usage {
	my $fh = shift;
	$fh = *STDOUT if (!defined $fh);
	print $fh "\n"; 
	print $fh "Usage: $progname [options] <window max> <output prefix>\n";
	print $fh "\n";
	print $fh "   Generates a list of pattern files and prints their names to stdout,\n";
	print $fh "   ordered from the  simplest to the most complex.\n";
 	print $fh "   <window max> is the maximum window size; a pattern will be generated\n";
	print $fh "   for every window size from 1 to max. For every size of window and\n";
 	print $fh "   every size of ngram (see -n), variants are generated depending on\n";
	print $fh "   whether unicode point and category as well as Elman features are\n";
	print $fh "   used or not (see options -p, -c, -e).\n";
 	print $fh "   The output files are named <output prefix><id><output suffix>, where\n";
 	print $fh "   by default <output suffix> is '$outputSuffix' (see option -a).\n";
 	print $fh "   Remark: if the prefix is a directory, the ending '/' must be supplied.\n";
 	print $fh "\n";
 	print $fh "  Options:\n";
	print $fh "    -h print this help message.\n";
	print $fh "    -a <output suffix> output filename ends with this instead of '$outputSuffix'.\n";
 	print $fh "    -n <ngram max> specify the n-gram max size; default: $ngramMaxSize;\n";
 	print $fh "       if higher than 1, features are added incrementally and the \n";
 	print $fh "       window size is iterated for every ngram size.\n";
 	print $fh "    -p <0|1|2> use unicode point: 0 = never, 1 = always; 2 = alternate;\n";
 	print $fh "       defaut: $useUnicodePoint.\n";
 	print $fh "    -c <0|1|2> use unicode categ: 0 = never, 1 = always; 2 = alternate;\n";
 	print $fh "       defaut: $useUnicodeCateg.\n";
 	print $fh "    -e <0|1|2> use Elman features: 0 = never, 1 = always; 2 = alternate;\n";
 	print $fh "       default: $useElman.\n";
 	print $fh "\n";
 	print $fh "\n";
 	print $fh "\n";
 	print $fh "\n";
 	print $fh "\n";
}




# PARSING OPTIONS
my %opt;
getopts('ha:n:p:c:e:', \%opt ) or  ( print STDERR "Error in options" &&  usage(*STDERR) && exit 1);
usage(*STDOUT) && exit 0 if $opt{h};
print STDERR "2 arguments expected, but ".scalar(@ARGV)." found: ".join(" ; ", @ARGV)  && usage(*STDERR) && exit 1 if (scalar(@ARGV) != 2);

my $windowMax = $ARGV[0];
my $outputPrefix = $ARGV[1];

$outputSuffix=$opt{a} if (defined($opt{a}));
$ngramMaxSize=$opt{n} if (defined($opt{n}));
$useUnicodePoint=$opt{p} if (defined($opt{p}));
$useUnicodeCateg=$opt{c} if (defined($opt{c}));
$useElman=$opt{e} if (defined($opt{e}));


for (my $ngramSize=1; $ngramSize<=$ngramMaxSize; $ngramSize++) {
    for (my $windowSize=1; $windowSize<=$windowMax; $windowSize++) {
	my $name = $outputPrefix."N".$ngramSize."W".$windowSize;
	generateForPoint($name, $ngramSize, $windowSize);
    }
}

sub generateForPoint {
    my ($name, $ngramSize, $windowSize) = @_;

    if ($useUnicodePoint == 2) {
	generateForCateg($name, $ngramSize, $windowSize, 0);
	generateForCateg($name, $ngramSize, $windowSize, 1);
    } else {
	generateForCateg($name, $ngramSize, $windowSize, $useUnicodePoint);
    }
}

sub generateForCateg {
    my ($name, $ngramSize, $useUnicodePoint) = @_;

    $name .= "P".$useUnicodePoint;
    if ($useUnicodeCateg == 2) {
	generateForElman($name, $ngramSize, $windowSize, $useUnicodePoint, 0);
	generateForElman($name, $ngramSize, $windowSize, $useUnicodePoint, 1);
    } else {
	generateForElman($name, $ngramSize, $windowSize, $useUnicodePoint, $useUnicodeCateg);
    }
}



sub generateForElman {
    my ($name, $ngramSize, $windowSize, $useUnicodePoint, $useUnicodeCateg) = @_;

    $name .= "C".$useUnicodeCateg;
    if ($useElman == 2) {
	generate($name, $ngramSize, $windowSize, $useUnicodePoint, $useUnicodeCateg, 0);
	generate($name, $ngramSize, $windowSize, $useUnicodePoint, $useUnicodeCateg, 1);
    } else {
	generate($name, $ngramSize, $windowSize, $useUnicodePoint, $useUnicodeCateg, $useElman);
    }
    
}

sub generate {
    my ($name, $ngramSize, $windowSize, $useUnicodePoint, $useUnicodeCateg, $useElman) = @_;

    $name .= "C".$useElman.$outputSuffix;

    my $wleft=int($windowSize/2);
    my $wright=int($windowSize/2);
    if ($windowSize % 2 != 0) {
	$wleft
    } 
	
    open(F, ">:encoding(utf-8)", $name) or die "Cannot write to '$name'";
    for (my $n=1; $n<=$ngramSize; $n++) {
	
    }

    
    close(F);

}




