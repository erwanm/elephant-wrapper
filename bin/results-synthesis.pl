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

my $progname = "results-synthesis.pl";


sub usage {
	my $fh = shift;
	$fh = *STDOUT if (!defined $fh);
	print $fh "\n"; 
	print $fh "Usage: $progname [options] <results file>\n";
	print $fh "\n";
	print $fh "  <results file> as generated by collect-results.sh\n";
	print $fh "\n";
 	print $fh "  Options:\n";
	print $fh "    -h print this help message.\n";
	print $fh "    -l <method> print only latex table for method <method> \n";
 	print $fh "\n";
}




# PARSING OPTIONS
my %opt;
getopts('hl:', \%opt ) or  ( print STDERR "Error in options" &&  usage(*STDERR) && exit 1);
usage(*STDOUT) && exit 0 if $opt{h};
print STDERR "1 arguments expected, but ".scalar(@ARGV)." found: ".join(" ; ", @ARGV)  && usage(*STDERR) && exit 1 if (scalar(@ARGV) != 1);

my $file =  $ARGV[0];
my $latexTable = $opt{l};

open(F, "<:encoding(utf-8)", $file) or die "Cannot open '$file'";
my %data;
my %size;
while (<F>) {
    chomp;
    my @cols=split;
    $size{$cols[0]} = $cols[2];
    $data{$cols[0]}->{baseline} = $cols[3];
    $data{$cols[0]}->{$cols[1].".crf"} = $cols[4];
    $data{$cols[0]}->{$cols[1].".elman"} = $cols[5];
}
close(F);

my %sum;
my %nb;
my %ranksum;
my $maxLength=0;
foreach my $dataset (keys %data) {
    $maxLength=length($dataset) if (length($dataset)>$maxLength);
    foreach my $method (keys %{$data{$dataset}}) {
	if ($data{$dataset}->{$method} ne "NA") {
	    $sum{$method} += $data{$dataset}->{$method};
	    $nb{$method}++;
	}
    }
    my @ranking = sort { $data{$dataset}->{$a} <=> $data{$dataset}->{$b} } grep { $data{$dataset}->{$_} ne "NA" }  (keys %{$data{$dataset}});
    for (my $r=0; $r < scalar(@ranking);$r++) {
	$ranksum{$ranking[$r]} += ($r+1);
    }
}

if (defined($latexTable)) {
    my @baselineBetterDatasets;
    my $m = $latexTable;
    print "Dataset & size (characters) & Baseline (% error rate) & $m \\\\\n";
    my $sumImprov=0;
    my $nb=0;
    my @improvs;
    foreach my $dataset (sort keys %data) {
	if ($data{$dataset}->{$m} ne "NA") {
	    my $b = $data{$dataset}->{baseline};
	    my $s = $data{$dataset}->{$m};
	    printf("%${maxLength}s\t& %9d\t& %7.4f\t& %7.4f\t\\\\\n", $dataset, $size{$dataset}, $b*100, $s*100);
	    if (($b != 0) && ($b>$s))  {
		$sumImprov += ($s -$b) / $b;
		push(@improvs, ($s -$b) / $b);
#		print STDERR "improv=".($s -$b) / $b."; sumImprov = $sumImprov, nb=$nb\n";
		$nb++;
	    }
	    if ($b < $s) {
		push(@baselineBetterDatasets, $dataset);
	    }
	}
    }
    $sumImprov = $sumImprov / $nb * 100;
    print "Info: ".scalar(@baselineBetterDatasets)." datasets for which baseline performs better than system: [".join(",",@baselineBetterDatasets)."]\n";
    print "Info: avg improvement WITHOUT the cases above = $sumImprov %\n";
 #   @improvs=sort { $a <=> $b } @improvs;
  #  print join(" ",@improvs)."\n";
    
} else {
    foreach my $method (sort keys %sum) {
	my $nb = $nb{$method};
	my $avg = $sum{$method} / $nb;
	my $avgrank = $ranksum{$method} / $nb ;
	print "$method\t$nb\t$avg\t$avgrank\n";
    }
}


    