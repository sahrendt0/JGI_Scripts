#!/usr/bin/env perl
## This script gets closely related organisms in mycocosm based on taxID
##USAGE : Reqires TaxID 
### related_DB.pl TaxonomyID <optional number of organisms>
## Original author: Sajeet Haridas, sharidas@lbl.gov

use warnings ;
use strict;
use LWP::Simple;

my $diemessage = "USAGE: $0 TaxonomyID <optional number of organisms>\nUsage requires a TaxonomyID and optional number of organisms [default = 5]\neg:: $0 1408161" ;
my $AscOut = "  --Cluster Aspnid1,AspGD_genes,physical \\\n  --ClusterOutgroup Aspnid1 \\\n" ;
my $BasOut = "  --Cluster Schco3,FilteredModels1,physical \\\n  --ClusterOutgroup Schco3 \\\n" ;
my $Basal =  "  --Cluster Batde5,FilteredModels2,physical \\\n  --ClusterOutgroup Batde5 \\\n" ;
my $outgrp = '' ;

if (!($ARGV[0])) { die "\n$diemessage\n\n" ;}
if (!($ARGV[0] =~ /^\d+$/)) { die "$diemessage\n" ; }
my $orgs = 5 ;
if (exists($ARGV[1])) { 
	if (!($ARGV[1] =~ /^\d+$/)) { die "$diemessage\n" ; }
	$orgs = "$ARGV[1]" ;
} 

my $lineageurl = 'http://genome.jgi.doe.gov/ext-api/mycocosm/species-tree/list-by-ncbi-lineage-taxon/'."$ARGV[0]".'?limit='."$orgs" ;
my $lineagecontent = get $lineageurl ;
die "Couldn't get data for taxon ID $ARGV[0] from $lineageurl\n" unless defined $lineagecontent;
my @rows = split /\n/, $lineagecontent; 
my %getdbs ; my @splt1 ; my $row ; my %dbignore ; my @dblist = () ; my $isbasal = 5 ; my $ignoredikarya = 0 ;
foreach $row (@rows) {
	if ($isbasal == 5) { 
		$isbasal = 0 ; 
		if ($row !~ /\-4751\-451864\-/) {$isbasal = 1 ;}
	}
	if ($isbasal == 1) {  ## See if the basal lineages are more that orgs requested. If so, we can ignore the dikarya.
		if ($row !~ /\-4751\-451864\-/) {$ignoredikarya = $ignoredikarya + 1 ;}
	}
}
if ($ignoredikarya>=$orgs) { $ignoredikarya = 1 ; } else {$ignoredikarya=0;}
foreach $row (@rows) {
	@splt1 = split(/\s+/, $row) ;
	if ($row =~ /\-$ARGV[0]$/) { $dbignore{$splt1[0]} = 'This_organism' ; next ; }
	if ($ignoredikarya == 1 and $row =~ /\-4751\-451864\-/) {next ;} ## This is dikarya, but we dont need to consider it.
	$getdbs{$splt1[0]} = $row ; push(@dblist,$splt1[0]) ;
	if ($row =~ /\-5204\-/ and $outgrp ne $Basal) { $outgrp = $AscOut ;} 
	elsif ($row =~ /\-4890\-/ and $outgrp ne $Basal) { $outgrp = $BasOut ;} 
	elsif ($ignoredikarya == 1) { $outgrp = $AscOut ;}
	else { $outgrp = $Basal ; } 
}

# my @dblist = keys(%getdbs) ;
my %params ; my $paramurl ; my $paramcontent ; my $key; my $val; my $thisdb ; my %gooddbs ;
foreach $thisdb (@dblist) {
	%params = ();
	$paramurl = 'http://genome.jgi.doe.gov/ext-api/genome-admin/'."$thisdb".'/parameters' ;
	$paramcontent = get $paramurl ;
	die "Couldn't get portal parameters for $thisdb from $paramurl\n" unless defined $paramcontent;
	@rows = split /\n/, $paramcontent;
	foreach $row (@rows) {
		($key, $val) = split /=/, $row, 2; 
		$params{$key} = $val;
	}
	if ( exists($params{supersededBy}) and $params{supersededBy} ne '' ) { $dbignore{$thisdb} = "supersededBy $params{supersededBy}" ; next ; } 
	if (!(exists($params{displayName}))) { $dbignore{$thisdb} = 'No_displayName' ; next ; } 
	if ( $params{displayName} =~ /copy/i ) { $dbignore{$thisdb} = 'Copy_in_displayName' ; next ; }
	if (!(exists($params{releaseDate})) and $params{isExternallySequencedOrganism} != 1) { $dbignore{$thisdb} = 'No_releaseDate' ; next ; } 
	if (!(exists($params{defaultAnalysisTrack}))) { $dbignore{$thisdb} = 'No_defaultAnalysisTrack' ; next ; } 
	$gooddbs{$thisdb} = $params{defaultAnalysisTrack} ;
}

my @baddb = sort(keys(%dbignore)) ;
print "\nThe following databases were ignored::\n" ;
foreach $thisdb (@baddb) {
	print "$thisdb\t$dbignore{$thisdb}\n" ;
}

print "\nFor use in sh::\n" ;
foreach $thisdb (@dblist) {
	if (exists($gooddbs{$thisdb})) { print '  --Vista ' ;  print "$thisdb \\\n" ; }
}
foreach $thisdb (@dblist) {
	if (exists($gooddbs{$thisdb})) {  print '  --Cluster ' ; print "$thisdb,$gooddbs{$thisdb},physical \\\n" ; }
}
print '  --ComparativeGenomes ' ;
$val = '' ;
foreach $thisdb (@dblist) { if (exists($gooddbs{$thisdb})) {  $val = "$val".','."$thisdb" ; } }
$val =~ s/^\,// ;
print $val ;
print " \\\n\n" ;

print "Suggested Outgroup::\n$outgrp\n\n" ;
