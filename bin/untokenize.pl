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

my $progname = "untokenize.pl";

my %parsemeFormat = ("tokenCol" => 2, "noSpaceAfterCol" => 3,  "noSpaceAfterValue" => "nsp");
my %udFormat = ("tokenCol" => 2, "noSpaceAfterCol" => 10,  "noSpaceAfterValue" => "SpaceAfter=No");
my %stdFormats = ( "parseme" =>  \%parsemeFormat, "UD" => \%udFormat );

my $defaultFormat = "UD";

my $format = $stdFormats{$defaultFormat};

my $debug=0;
my $iobFormat=0;
my $sentenceLabel=0;

my $contractionMgmt = 0;
my $indexCol; # used only if $contractionMgmt is 1.

my $bLabel ="B";
my $iLabel ="I";
my $oLabel ="O";
my $sLabel;

sub usage {
	my $fh = shift;
	$fh = *STDOUT if (!defined $fh);
	print $fh "\n"; 
	print $fh "Usage: $progname [options] <tokenized text>\n";
	print $fh "\n";
	print $fh "  Converts a tokenized text which contains space indications (by \n";
	print $fh "  default in UD .conllu format) either to the 'iob' format required\n";
	print $fh "  by elephant (see option -i) or to raw text.\n";
	print $fh "\n";
	print $fh "  Remark: option '-f' is meant to change the format to a different\n";
	print $fh "          standard format. If another option among '-c', '-s', '-v' is\n";
	print $fh "          used as well, the default format is the one selected with '-f'.\n";
 	print $fh "\n";
 	print $fh "  Options:\n";
	print $fh "    -h print this help message.\n";
	print $fh "    -i output in IOB format for elephant training (one char by line:\n";
	print $fh "       unicode value then IOB label)\n";
	print $fh "    -d debug mode: print additional third column with actual character\n";
	print $fh "       (only in IOB mode).\n";
	print $fh "    -f <format name>. Available format: [".join(",", keys %stdFormats)."]; default: $defaultFormat.\n";
	print $fh "    -c <token col no> read token in this column. Default: ".$stdFormats{$defaultFormat}->{tokenCol}.".\n";
	print $fh "    -s <'no space after' col no> column possibly containing indication\n";
	print $fh "        of 'no space after'; default: ".$stdFormats{$defaultFormat}->{noSpaceAfterCol}."\n";
	print $fh "    -v <'no space after' value> value that the column contains which\n";
	print $fh "       indicates 'no space after'. Default: ".$stdFormats{$defaultFormat}->{noSpaceAfterValue}."\n";
 	print $fh "    -C <index col no> deal with potential contractions in the data,\n";
	print $fh "       e.g. actual token \"didn't\" at index 3-4 is followed by \"did\"\n";
 	print $fh "       at index 3 then \"'nt\" at index 4. The script will keep only the\n";
	print $fh "       actual token, recognized by its interval index N-M, and ignore \n";
	print $fh "       indexes N to M. Regular indexes (I;e., not ranges) must follow\n";
	print $fh "       the pattern \\d+(\\.\\d+)?\n";
	print $fh "    -S <S label> mark sentence begining as well with <S label>; \n";
	print $fh "       default: only tokens (labels B,I,O); used only in IOB mode.\n";
	print $fh "    -B <B label> to use if label is not B.\n";
        print $fh "    -I <I label> to use if label is not I.\n";
        print $fh "    -O <O label> to use if label is not O.\n";
  	print $fh "\n";
}


sub printToken {
    my ($token, $spaceBefore, $newSentence) = @_;

    if ($iobFormat) {
	print ord(" ")."\t$oLabel\n" if ($spaceBefore);
	if (length($token)>0) {
	    my $annot = ($newSentence && $sentenceLabel) ? "\t$sLabel" : "\t$bLabel";
	    my $c = substr($token,0,1);
	    $annot .= "\t$c" if ($debug);
	    print ord($c).$annot."\n";
	    for (my $i=1; $i<length($token); $i++) {
		my $annot = "\t$iLabel";
		my $c = substr($token,$i,1);
		$annot .= "\t$c" if ($debug);
		print ord($c).$annot."\n";
	    }
	}
    } else {
	if (($newSentence) && ($spaceBefore)) {
	    print "\n" ;
	} else { # dont print a space if new sentence (start of line)
	    print " " if ($spaceBefore);
	}
	print $token;
    }
}



# PARSING OPTIONS
my %opt;
getopts('hf:c:s:v:diC:S:B:I:O:', \%opt ) or  ( print STDERR "Error in options" &&  usage(*STDERR) && exit 1);
usage(*STDOUT) && exit 0 if $opt{h};
print STDERR "1 arguments expected, but ".scalar(@ARGV)." found: ".join(" ; ", @ARGV)  && usage(*STDERR) && exit 1 if (scalar(@ARGV) != 1);

my $inputFile =  $ARGV[0];


if (defined($opt{f})) {
    die "Error: no format '$opt{f}'available, aborting." if (!defined($stdFormats{$opt{f}}));
    $format = $stdFormats{$opt{f}} 
    
}
$format->{"tokenCol"} = $opt{c} if defined($opt{c});
$format->{"noSpaceAfterCol"} = $opt{s} if defined($opt{s});
$format->{"noSpaceAfterValue"}  = $opt{v} if defined($opt{v});
$debug = 1 if  (defined($opt{d}));
$iobFormat = 1 if  (defined($opt{i}));

$sLabel=$opt{S};
$bLabel =$opt{B} if (defined($opt{B}));
$iLabel =$opt{I} if (defined($opt{I}));
$oLabel =$opt{O} if (defined($opt{O}));



if (defined($opt{C})) {
    $contractionMgmt = 1 ;
    my $indexCol = $opt{C} -1;
}


my $tokenCol = $format->{"tokenCol"}-1;
my $tokenNSA = $format->{"noSpaceAfterCol"}-1;
my $nsa = $format->{"noSpaceAfterValue"};

my %freqByToken;
my $total = 0;
my $newSent = 1;
my $noSpaceAfter = 1;

my $cEnd=-1; # used only if $contractionMgmt is 1

open(F, "<:encoding(utf-8)", $inputFile) or die "Cannot open '$inputFile'";
while (<F>) {
    chomp;
    if  (m/./) {
	if (!m/^#/) {
	    chomp;
	    my @cols = split("\t", $_);
	    my $processToken = 1;
	    if ($contractionMgmt) {
		my $index=$cols[0];
		if ($index =~ m/^\d+(\.\d+)?$/) {
		    if ($index <= $cEnd) {
			#			print STDERR "DEBUG ignoring index $index\n";
			# REMARK: we assume that the 'no space after' mark is NEVER in the expanded range!
			$processToken = 0;
		    }
		} else {
		    die "Invalid index range '$index'" if ($index !~ m/^\d+-\d+$/);
		    my $cStart; # unused since the range to ignore always starts just after the contraction
		    ($cStart, $cEnd) = ($index =~ m/^(\d+)-(\d+)$/);
		    die "Invalid index range '$index', but most likely bug" if (!defined($cStart) || !defined($cEnd));
#		    print STDERR "found contraction range $index, end=$cEnd\n";
		}
	    }
	    if ($processToken) {
		my $token=$cols[$tokenCol];
		printToken($token, !$noSpaceAfter, $newSent);
		$noSpaceAfter = ($cols[$tokenNSA] =~ m/$nsa/) ? 1 : 0 ;
		#	print STDERR "tokenCol=$tokenCol".join(";", @cols)."\n";
		$newSent = 0;
		$freqByToken{$token}++;
		$total++;
	    }
	}
    } else {
	$newSent = 1;
	$cEnd = -1;
    }
}
printToken("", !$noSpaceAfter, 1); # apply the "noSpaceAfter" for the last token
close(F);

#print STDERR "Info: read $total tokens.\n";

