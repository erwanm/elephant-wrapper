#!/usr/bin/perl

use strict;
use warnings;

my $n=0;
while (<STDIN>) {
    chomp;
    if (m/./) {
	$n++;
	print "$n\t$_\n";
    } else {
	print "\n";
	$n=0;
    }
}
