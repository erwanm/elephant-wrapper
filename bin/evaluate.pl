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

my $progname = "evaluate.pl";

my $iobCol =2;

sub usage {
	my $fh = shift;
	$fh = *STDOUT if (!defined $fh);
	print $fh "\n"; 
	print $fh "Usage: $progname [options] <iob predicted file>[:col]  <iob gold file>[:col]\n";
	print $fh "\n";
	print $fh "  Evaluates tokenization, prints:\n";
	print $fh "    <total chars> <nb errors> <error rate> <accuracy>\n";
	print $fh "\n";
 	print $fh "  Options:\n";
	print $fh "    -h print this help message.\n";
	print $fh "    -c <default IOB column> default: $iobCol.\n";
 	print $fh "\n";
}


# $f = either filename or filename:colno
sub readFileCol {
    my ($f) = @_;

    my $colno=$iobCol;
    if ($f =~ m/:/) {
	($f, $colno)= ($f =~ m/^(.*):(.*)$/);
    }
    $colno--;
    my @res;
    open(F, "<:encoding(utf-8)", $f) or die "Cannot open '$f'";
    while (<F>) {
	chomp;
	my @cols=split;
	push(@res, $cols[$colno]);
    }
    close(F);
    return \@res;
}


# PARSING OPTIONS
my %opt;
getopts('hc:', \%opt ) or  ( print STDERR "Error in options" &&  usage(*STDERR) && exit 1);
usage(*STDOUT) && exit 0 if $opt{h};
print STDERR "2 arguments expected, but ".scalar(@ARGV)." found: ".join(" ; ", @ARGV)  && usage(*STDERR) && exit 1 if (scalar(@ARGV) != 2);

my $predFile =  $ARGV[0];
my $goldFile =  $ARGV[1];

$iobCol=$opt{c} if (defined($opt{c}));


my $answersPred = readFileCol($predFile);
my $answersGold = readFileCol($goldFile);

die "Error: different number of instances in $predFile and $goldFile." if (scalar(@$answersPred) != scalar(@$answersGold));

my $nbErr=0;

for (my $i=0; $i<scalar(@$answersPred); $i++) {
    if ($answersPred->[$i] ne $answersGold->[$i]) {
	$nbErr++;
    }
}

printf("%d\t%d\t%.8f\t%.8f\n", scalar(@$answersPred), $nbErr, $nbErr/scalar(@$answersPred), 1-$nbErr/scalar(@$answersPred));

