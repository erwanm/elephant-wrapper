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

my $bLabel ="B";
my $iLabel ="I";
my $oLabel ="O";
my $iobCol =2;

sub usage {
	my $fh = shift;
	$fh = *STDOUT if (!defined $fh);
	print $fh "\n"; 
	print $fh "Usage: $progname [options] <iob predicted file>[:col]  <iob gold file>[:col]\n";
	print $fh "\n";
	print $fh "  Evaluates tokenization, prints:\n";
	print $fh "    <total chars> <nb errors> <error rate> <accuracy> <total words gold>\n";
	print $fh "                                 <total words pred> <precision> <recall>\n";
	print $fh "\n";
 	print $fh "  Options:\n";
	print $fh "    -h print this help message.\n";
	print $fh "    -c <IOB column> default: $iobCol.\n";
        print $fh "    -B <B label> to use if label is not B.\n";
        print $fh "    -I <I label> to use if label is not I.\n";
        print $fh "    -O <O label> to use if label is not O.\n";
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


#
# counts the number of correct tokens in $probeVector wrt $refVector, returns ($nbCorrect, $nbTotal).
#
# if using predicted as probe and gold as ref, this can give the recall: (TP, gold positives);
# if using gold as probe and predicted as ref, this can give the precision: (TP, predicted positives).
#
#
sub countCorrectWrtRef {
    my ($refVector, $probeVector) = @_;

    my $i=0;
    my ($nbCorrect, $nbTotal) = (0,0);
    while ($i<scalar(@$refVector)) {
	if ($refVector->[$i] eq $bLabel) {
	    $nbTotal++;
	    if ($probeVector->[$i] eq $bLabel) { # same start ok
		$i++;
		while ( ($i<scalar(@$refVector)) && ($refVector->[$i] eq $iLabel) && ($probeVector->[$i] eq $iLabel) ) {  # same inside
		    $i++;
		}
		$nbCorrect++ if (($i==scalar(@$refVector)) || ( ($refVector->[$i] ne $iLabel) && ($probeVector->[$i] ne $iLabel) ) ); # same end
		$i--; # because $i will be incremented later, so that we don't skip the first char after the token
	    }
	}
	$i++;
    }
    return ($nbCorrect, $nbTotal);
}




# PARSING OPTIONS
my %opt;
getopts('hc:B:I:O:', \%opt ) or  ( print STDERR "Error in options" &&  usage(*STDERR) && exit 1);
usage(*STDOUT) && exit 0 if $opt{h};
print STDERR "2 arguments expected, but ".scalar(@ARGV)." found: ".join(" ; ", @ARGV)  && usage(*STDERR) && exit 1 if (scalar(@ARGV) != 2);

my $predFile =  $ARGV[0];
my $goldFile =  $ARGV[1];

$iobCol=$opt{c} if (defined($opt{c}));
$bLabel =$opt{B} if (defined($opt{B}));
$iLabel =$opt{I} if (defined($opt{I}));
$oLabel =$opt{O} if (defined($opt{O}));


my $answersPred = readFileCol($predFile);
my $answersGold = readFileCol($goldFile);

die "Error: different number of instances in $predFile and $goldFile." if (scalar(@$answersPred) != scalar(@$answersGold));

my $nbErr=0;

for (my $i=0; $i<scalar(@$answersPred); $i++) {
    if ($answersPred->[$i] ne $answersGold->[$i]) {
	$nbErr++;
    }
}

my ($tp1, $rp) = countCorrectWrtRef($answersGold, $answersPred);
my ($tp2, $pp) = countCorrectWrtRef($answersPred, $answersGold);
die "Bug: different number of TP cases: $tp1, $tp2" if ($tp1 != $tp2);
my $recall= $tp1 / $rp;
my $prec = $tp2 / $pp;

printf("%d\t%d\t%.8f\t%.8f\t%d\t%d\t%.8f\t%.8f\n", scalar(@$answersPred), $nbErr, $nbErr/scalar(@$answersPred), 1-$nbErr/scalar(@$answersPred), $rp, $pp, $prec, $recall);

