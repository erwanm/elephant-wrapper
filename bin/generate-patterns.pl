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
my $windowMax=8;
my $useUnicodePoint=2;
my $useUnicodeCateg=2;
my $useElman=2;
my $nbTopElman=10; 
my $startElmanCol=2;
my $useTemplateBigram=1;


sub usage {
	my $fh = shift;
	$fh = *STDOUT if (!defined $fh);
	print $fh "\n"; 
	print $fh "Usage: $progname [options] <output prefix>\n";
	print $fh "\n";
	print $fh "   Generates a list of pattern files and prints their names to stdout,\n";
	print $fh "   ordered from the  simplest to the most complex.\n";
 	print $fh "   A pattern will be generated for every size of ngram cumulatively,\n";
	print $fh "   then for every window size from 1 to max (see options -n, -w). For\n";
 	print $fh "   every size of window and every size of ngram, variants are\n";
	print $fh "   generated depending on whether unicode point and category as well\n";
	print $fh "   as Elman features are used or not (see options -p, -c, -e, -b).\n";
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
 	print $fh "    -w <max window size>; default: $windowMax.\n";
 	print $fh "    -p <0|1|2> use unicode point: 0 = never, 1 = always; 2 = alternate;\n";
 	print $fh "       defaut: $useUnicodePoint.\n";
 	print $fh "    -c <0|1|2> use unicode categ: 0 = never, 1 = always; 2 = alternate;\n";
 	print $fh "       defaut: $useUnicodeCateg.\n";
 	print $fh "    -e <0|1|2> use Elman features: 0 = never, 1 = always; 2 = alternate;\n";
 	print $fh "       default: $useElman.\n";
 	print $fh "    -b <0|1|2> use Bigram in Wapiti template: 0 = never, 1 = always;\n";
 	print $fh "               2 = alternate; default: $useTemplateBigram.\n";
 	print $fh "    -s <parameters string> provide values for all the parameters at once,\n";
 	print $fh "       separated by commas: <n>,<w>,<p>,<c>,<e>,<b>; This option takes\n";
 	print $fh "       precedence over any other.\n";
 	print $fh "\n";
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
    my ($name, $ngramSize, $windowSize, $useUnicodePoint) = @_;

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
	generateForBigram($name, $ngramSize, $windowSize, $useUnicodePoint, $useUnicodeCateg, 0);
	generateForBigram($name, $ngramSize, $windowSize, $useUnicodePoint, $useUnicodeCateg, 1);
    } else {
	generateForBigram($name, $ngramSize, $windowSize, $useUnicodePoint, $useUnicodeCateg, $useElman);
    }
    
}


sub generateForBigram {
    my ($name, $ngramSize, $windowSize, $useUnicodePoint, $useUnicodeCateg, $useElman) = @_;

    $name .= "E".$useElman;
    if ($useTemplateBigram == 2) {
	generate($name, $ngramSize, $windowSize, $useUnicodePoint, $useUnicodeCateg, $useElman, 0);
	generate($name, $ngramSize, $windowSize, $useUnicodePoint, $useUnicodeCateg, $useElman, 1);
    } else {
	generate($name, $ngramSize, $windowSize, $useUnicodePoint, $useUnicodeCateg, $useElman, $useTemplateBigram);
    }
    
}





sub generate {
    my ($name, $ngramSize, $windowSize, $useUnicodePoint, $useUnicodeCateg, $useElman, $useBigram) = @_;

    $name .= "B".$useBigram.$outputSuffix;
    # we don't generate the case where both $useUnicodePoint and $useUnicodeCateg are zero
    if (($useUnicodePoint!=0) || ($useUnicodeCateg!=0)) {

	my $wleft=int($windowSize/2);
	my $wright=int($windowSize/2);
	if ($windowSize % 2 != 0) {
	    $wleft++;
	} 
	
	open(F, ">:encoding(utf-8)", $name) or die "Cannot write to '$name'";

	# use bigram? (not sure how this works really, just copying from the Elephant templates)
	print F "B\n" if ($useBigram); 
	
	for (my $n=1; $n<=$ngramSize; $n++) {
	    print F generateTemplateLine($n, 0, 0, 0)."\n" if ($useUnicodePoint);
	    print F generateTemplateLine($n, 1, 0, 0)."\n" if ($useUnicodeCateg);
	    for (my $l=1; $l<=$wleft; $l++) {
		print F generateTemplateLine($n, 0, -$l)."\n" if ($useUnicodePoint);
		print F generateTemplateLine($n, 1, -$l)."\n" if ($useUnicodeCateg);
	    }
	    for (my $r=1; $r<=$wright; $r++) {
		print F generateTemplateLine($n, 0, $r)."\n" if ($useUnicodePoint);
		print F generateTemplateLine($n, 1, $r)."\n" if ($useUnicodeCateg);
	    }
	    print F "\n";
	}
	
	if ($useElman) { # add Elman top 10
	    for (my $e=0; $e < $nbTopElman; $e++) {
		print F "*100:%x[0,".($e+$startElmanCol)."]\n";
	    }
	}
	print F "\n";

	
	close(F);
    }
}


sub generateTemplateLine {

    my ($nsize, $col, $pos) = @_;

    # id part
    my $idpos;
    if ($pos==0) {
	$idpos="X0";
    } else {
	if ($pos<0) {
	    $idpos="L".(-$pos);
	} else {
	    $idpos="R".$pos;
	}
    }
    my $idline = "N${nsize}F${col}${idpos}";
    
    # feature part
    my $start = $pos-int($nsize/2); # centering the ngram window on the current pos, with one more on the left if odd n
    my @featParts;
    for (my $n=$start; $n<$start+$nsize; $n++) {
	push(@featParts, "%X[$n,$col]");
    }
    return "U:$idline = ".join("/", @featParts);
}





# PARSING OPTIONS
my %opt;
getopts('ha:n:w:p:c:e:b:s:', \%opt ) or  ( print STDERR "Error in options" &&  usage(*STDERR) && exit 1);
usage(*STDOUT) && exit 0 if $opt{h};
print STDERR "1 arguments expected, but ".scalar(@ARGV)." found: ".join(" ; ", @ARGV)  && usage(*STDERR) && exit 1 if (scalar(@ARGV) != 1);

my $outputPrefix = $ARGV[0];

$outputSuffix=$opt{a} if (defined($opt{a}));

if (defined($opt{s})) {
    ($ngramMaxSize, $windowMax, $useUnicodePoint, $useUnicodeCateg, $useElman, $useTemplateBigram) = split(",",$opt{s});
} else {
    $ngramMaxSize=$opt{n} if (defined($opt{n}));
    $windowMax = $opt{w} if (defined($opt{w}));
    $useUnicodePoint=$opt{p} if (defined($opt{p}));
    $useUnicodeCateg=$opt{c} if (defined($opt{c}));
    $useElman=$opt{e} if (defined($opt{e}));
    $useTemplateBigram=$opt{b} if (defined($opt{b}));
}
    



for (my $ngramSize=1; $ngramSize<=$ngramMaxSize; $ngramSize++) {
    for (my $windowSize=1; $windowSize<=$windowMax; $windowSize++) {
	my $name = $outputPrefix."N".$ngramSize."W".$windowSize;
	generateForPoint($name, $ngramSize, $windowSize);
    }
}





