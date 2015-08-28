#!/usr/bin/env perl
## This script prints out one fasta record from a file based on sequence name.

use warnings ;
use strict;


if (!$ARGV[0]) { die "USAGE: $0 pattern\nWhere pattern is a text pattern match in the record header.\n" ; }

open (INFL1, "/global/dna/projectdirs/fungal/pipeline/pipeline_data/CEGMA/core.fa") or die "Cannot open CEGMA core.fa\n" ;

my $wrt = 0 ; 
while (<INFL1>) {
	if (/^>/) {$wrt = 0 ;}
	if (/$ARGV[0]/) {$wrt = 1 ;}
	if ($wrt == 1) { print $_ ;}
}
