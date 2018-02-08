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
	print $fh "   into N parts, each containing approximately the same number of sentences.\n";
 	print $fh "   The output files are named <output prefix><index><output suffix>, where\n";
 	print $fh "   by default <output prefix> is the input filename and <output suffix> is empty\n";
	print $fh "   (see options -b and -a).\n";
 	print $fh "\n";
 	print $fh "  Options:\n";
	print $fh "    -h print this help message.\n";
	print $fh "    -s shuffle sentences. Default: split using contiguous sets of sentences. NOT IMPLEMENTED YET\n";
	print $fh "    -b <output prefix> output filename starts with this (default: input filename dot).\n";
	print $fh "       Remark: the prefix can include a directory path, provided this path already exists.\n";
	print $fh "    -a <output suffix> output filename ends with this (default: empty string).\n";
	print $fh "    -p The argument <N> is interpreted as a proportion, and the input is split into\n";
	print $fh "       two parts of relative size N and 1-N.\n";
 	print $fh "    -c <cut down size> first restrict the size to this number of sentences.\n";
	print $fh "    -v verbose mode, print size of every dataset to STDOUT.\n";
 	print $fh "\n";
}


sub writeSentenceSubsetToFile {
    my ($subset, $sentences, $filename) = @_;

    open(OUT, ">:encoding(utf-8)", $filename) or die "Cannot open '$filename' for writing";
    foreach my $index (@$subset)  {
	my $sent = $sentences->[$index];
	foreach my $line (@$sent) {
	    print OUT $line."\n";
	}
	print OUT "\n";
    }
    close(OUT);
    
}

#
# return a hash: res->{$id}->[$i] = $sentId means that sentence $sentId belongs to subset $id
#
sub splitNIntoMEqualSubsets {
    my ($n, $m) = @_;

    my %res;
    my $nbByBin =  $n / $m; # potentially decimal number
    die "Cannot split $n sentences into $m parts." if ($nbByBin < 1);

    my $maxDigit = length($m -1);

    for (my $bin=0; $bin<$m; $bin++)  {
	my $binId = sprintf("%0${maxDigit}d", $bin);
	my $start = int($bin * $nbByBin);
	my $end = int(($bin+1) * $nbByBin) -1;
	$end = $n -1 if ($bin+1 == $m); # adjust last bin end in case integer truncation falls short
	my @indexes = ($start .. $end);
	$res{$binId} = \@indexes;
    }
    return \%res;
}


sub printSizeSubsets {
    my ($total, $subsets) = @_;

    foreach my $subsetId (keys %$subsets) {
	my $nb = scalar(@{$subsets->{$subsetId}});
	printf("$subsetId: %d (%6.2f %%)\n", $nb , $nb * 100 / $total);
    }
}


# PARSING OPTIONS
my %opt;
getopts('hsb:a:pvc:', \%opt ) or  ( print STDERR "Error in options" &&  usage(*STDERR) && exit 1);
usage(*STDOUT) && exit 0 if $opt{h};
print STDERR "2 arguments expected, but ".scalar(@ARGV)." found: ".join(" ; ", @ARGV)  && usage(*STDERR) && exit 1 if (scalar(@ARGV) != 2);

my $N = $ARGV[0];
my $inputFile =  $ARGV[1];

die "Error: option -r not implemented yet!" if (defined($opt{r}));

my $outputPrefix = (defined($opt{b})) ? $opt{b} : $inputFile.".";
my $outputSuffix = (defined($opt{a})) ? $opt{a} : "";

my $proportion = defined($opt{p});
die "Error: invalid proportion $N with option -p, N must be lower than 1" if ($proportion && ($N>1));
my $verbose =  defined($opt{v});

my $cutDownToSize = (defined($opt{c})) ? $opt{c} : 0;

my @corpus;
my $sent;

# 1 read full content of input file, stored as $corpus[$sentNo]->[$tokenNo]
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


if ($cutDownToSize>0) {
    if ($cutDownToSize > scalar(@corpus)) {
	die "Error: corpus too small, cannot cut down size from ".scalar(@corpus)." to $cutDownToSize."
    }
    @corpus=@corpus[0..$cutDownToSize-1];
}


# 2. calculate subsets

my $subsets;
if ($proportion) {
    my $nbSent1 = int($N * scalar(@corpus));
    my @l1 = (0..$nbSent1-1);
    $subsets->{1} = \@l1;
    my @l2 = ($nbSent1..scalar(@corpus)-1);
    $subsets->{2} = \@l2;
} else {
    $subsets = splitNIntoMEqualSubsets(scalar(@corpus), $N);
}
printSizeSubsets(scalar(@corpus), $subsets) if ($verbose); 

# 3. write subsets to files

foreach my $subsetId (keys %$subsets) {
    writeSentenceSubsetToFile($subsets->{$subsetId}, \@corpus, $outputPrefix.$subsetId.$outputSuffix);
}

