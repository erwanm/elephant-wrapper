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

my $progname = "generic-tokenizer.pl";

my $iobFormat=0;
my $bLabel="B";
my $iLabel="I";
my $oLabel="O";
my $debug=0;

sub usage {
	my $fh = shift;
	$fh = *STDOUT if (!defined $fh);
	print $fh "\n"; 
	print $fh "Usage: $progname [options] <text file>\n";
	print $fh "\n";
 	print $fh "\n";
 	print $fh "  Options:\n";
	print $fh "    -h print this help message.\n";
	print $fh "    -d debug for iob mode: print 3rd column with character.\n";
	print $fh "    -i output in IOB format (one char by line: unicode value then IOB label)\n";
	print $fh "    -b <B label> to use if label is not B (used only if -i).\n";
	print $fh "    -i <I label> to use if label is not I (used only if -i).\n";
	print $fh "    -o <O label> to use if label is not O (used only if -i).\n";
 	print $fh "    -l do not replace line breaks with a space character (default: replace).\n";
 	print $fh "\n";
}





# PARSING OPTIONS
my %opt;
getopts('hiBIOdl', \%opt ) or  ( print STDERR "Error in options" &&  usage(*STDERR) && exit 1);
usage(*STDOUT) && exit 0 if $opt{h};
print STDERR "1 arguments expected, but ".scalar(@ARGV)." found: ".join(" ; ", @ARGV)  && usage(*STDERR) && exit 1 if (scalar(@ARGV) != 1);

my $inputFile =  $ARGV[0];

$iobFormat = 1 if  (defined($opt{i}));
$bLabel =$opt{B} if (defined($opt{B}));
$iLabel =$opt{I} if (defined($opt{I}));
$oLabel =$opt{O} if (defined($opt{O}));
$debug = 1 if ($opt{d});
my $replaceLineBreaksWithSpaces = (defined($opt{l})) ? 0 : 1 ;


open(F, "<:encoding(utf-8)", $inputFile) or die "Cannot open '$inputFile'";
my $lastPrintedSpace=1; # no need for space at the beginning
while (<F>) {
    my $line;
    if ($replaceLineBreaksWithSpaces) {
	chomp;
	$line = $_." "; # adding space at the end to replace end of line
    }  else {
	$line = $_;
    }
    my $pos = 0;
    while ($pos<length($line)) {

	# 1 possibly sequence of whitespace chars
	while (($pos<length($line)) &&  (substr($line,$pos,1) =~ m/\s/)) {
	    my $d = ($debug)  ? "\t".substr($line,$pos,1) : "";
	    print ord(substr($line,$pos,1))."\t$oLabel$d\n" if ($iobFormat);
	    $pos++;
	}

	if (!$iobFormat && !$lastPrintedSpace) { # in default text format, multiple spaces are replace with single space char.
	    print " ";
	    $lastPrintedSpace=1;
	}

	# 2 read a token: punct or word or special token (email, http address, number)
	if ($pos<length($line)) {
	    my $remaining = substr($line, $pos);
	    my $token;
	    if ($remaining =~ m/^\p{L}+/) { # word
		($token) = ($remaining =~ m/^(\p{L}+)/);
	    } elsif ($remaining =~ m/^([a-z0-9_\.-]+)@([\da-z\.-]+)\.([a-z\.]{2,6})/) { # email
		($token) = ($remaining =~ m/^((?:[a-z0-9_\.-]+)@(?:[\da-z\.-]+)\.(?:[a-z\.]{2,6}))/);
	    } elsif ($remaining =~ m/^(?:https?:\/\/)(?:[\da-z\.-]+)\.(?:[a-z\.]{2,6})(?:[\/\w_\.-]*)*\/?/) { # http address
		($token) = ($remaining =~ m/^((?:https?:\/\/)(?:[\da-z\.-]+)\.(?:[a-z\.]{2,6})(?:[\/\w_\.-]*)*\/?)/);
	    } elsif ($remaining =~ m/^\-?([0-9]*[.,]?)*[0-9]+/) { # number
		($token) = ($remaining =~ m/^(\-?(?:[0-9]*[.,]?)*[0-9]+)/);
	    } elsif ($remaining =~ m/^[^\s\p{L}0-9]+/) { # punct
		($token) = ($remaining =~ m/^([^\s\p{L}0-9]+)/);
	    } else { # anything else, i.e. something with at least one digit inside
		($token) = ($remaining =~ m/^\W+/);
		print STDERR "DEBUG: '$token'\n";
		die "BUG1: '$remaining'" if (!length($token));
	    }
	    die "BUG2 '$remaining'" if (!length($token));
#	    print STDERR "DEBUG: '$token'\n";
	    if ($iobFormat) {
		my $d = ($debug)  ? "\t".substr($token,0,1) : "";
		print ord(substr($token,0,1))."\t$bLabel$d\n";
		for (my $i=1; $i<length($token); $i++) {
		    my $d = ($debug)  ? "\t".substr($token,$i,1) : "";
		    print ord(substr($token,$i,1))."\t$iLabel$d\n";
		}
	    } else {
		print "$token";
		$lastPrintedSpace=0;
	    }
	    $pos += length($token);
	}
    }
}
close(F);
