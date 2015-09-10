#!/usr/bin/perl
# Script: get_segDup_perScf.pl
# Description: Uses a list of non-duploid segmental duplication protein IDs and reports what proportion of total models on a particular scaffold they represent. 
# Author: Steven Ahrendt
# email: sahrendt0@gmail.com
# Date: 09.09.2015
##################################
use warnings;
use strict;
use Getopt::Long;
#use lib '/global/homes/s/sahrendt/Scripts';
#use SeqAnalysis;
use Data::Dumper;
use Bio::Tools::GFF;

#####-----Global Variables-----#####
my $input;
my ($help,$verb);
my %data; # Stores data about each scaffold
my $COV_THRESHOLD = 0;  # percent threshold for printing results
my $dbName;
my $userName;
my $hostName="gpdb03.nersc.gov";

GetOptions ('d|database=s' => \$dbName,
            'user=s' => \$userName,
            'host=s' => \$hostName,
            'coverage=i' => \$COV_THRESHOLD,
            'h|help'   => \$help,
            'v|verbose' => \$verb);
my $usage = "Usage: get_segDup_perScf.pl -d dbName --user userName [--host hostName]
Description: Uses a list of non-duploid segmental duplication protein IDs 
             and reports what proportion of total models on a particular scaffold they represent.\n";
die $usage if $help;
die "Please provide a database name.\n$usage" if (!$dbName);
die "Please provide a username.\n$usage" if (!$userName);

#####-----Main-----#####
## Step 0. get scaffold info
my $len_file = "$dbName\_Len.tsv";
my $fm_file = "$dbName\_FMs.tsv";
my $gff = "$dbName\.gff3";
my $unique_file = "$dbName\_uniqueSegmental";

mkScfLen() unless (-e $len_file); ## Create scaffold length distribution 
mkScfFm() unless (-e $fm_file);   ## Create distribution of filtered models 
mkGFF() unless (-e $gff); ## Create gff flatfile 
uniqSeg() unless (-e $unique_file); ## Create unique segmental duplication file 

## Step 1. populate hash w/ scaffold info
storeData($len_file,"length");
storeData($fm_file,"numFMs");

## Step 2. Store uniqueSegmental list
my %unique = simplerHash($unique_file);

## Step 3. Get model sources from GFF file
open(my $in,"<",$gff) or die "Can't open $gff: $!\n";
while (my $line = <$in>)
{
  next if ($line =~ /^#/);
  chomp $line;
  my ($seq_id,$src,$type,$start,$end,$score,$strand,$phase,$attributes) = split(/\t/,$line);
  next if ($type ne "mRNA");
  my($ID,$PARENT,$NAME,$PROTID) = split(/;/,$attributes);
  my $gff_protID = (split(/=/,$PROTID))[1];
  #print $gff_protID,"\n";
  if (exists $unique{$gff_protID})
  {
    push (@{$data{$seq_id}{"segs"}},$gff_protID);
  }
}
close($in);

## Step 4. Output
my $total;
print "Scf\tsegDups\ttotalModels\tpercent\n";
foreach my $key (sort {(split(/_/,$a))[1] <=> (split(/_/,$b))[1]} keys %data)
{
  if(exists $data{$key}{"segs"})
  {
    my $segDups = scalar @{$data{$key}{"segs"}};

    my $fms = $data{$key}{"numFMs"};
    my $percent = sprintf("%.2f",($segDups/$fms)*100);
    if($percent > $COV_THRESHOLD)
    {
      print join("\t",$key,$segDups,$fms,$percent),"\n";
      $total+=$segDups;
    }
  }
}
#print Dumper \%data;
warn "\n$total unique segmental duplications\n";

warn "Done.\n";
exit(0);

#####-----Subroutines-----#####
######
# Submits a mysql query using credentials provided
#################
sub sqlQueryWrite {
  my $query = shift @_;
  my $file = shift @_;
  my $sql_login = "mysql -h $hostName -u $userName -p $dbName";
  system("$sql_login -e '$query' > $file");
}

#####
# creates a GFF file from an organism database
#############
sub mkGFF {
  my $gff_dmp = "/global/dna/projectdirs/fungal/pipeline/DEFAULT/bin/euk/gat/jgidumpGFF3";
  my $track = "FilteredModels1";
  system("$gff_dmp -h $hostName -d $dbName -o $gff $track");
}

####
# Selects protein IDs which are unique to the segmental duplicated gene set
#   and which are not diploids
############
sub uniqSeg {
  my $sql_query = "SELECT seg_dups.proteinId_1 FROM (SELECT proteinId_1 FROM segmental_duplication_protein_pairs UNION SELECT proteinId_2 FROM segmental_duplication_protein_pairs) AS seg_dups LEFT JOIN (SELECT proteinId_1 FROM ploidy_orth_dip_pairs WHERE is_diploid_pair=1) AS diploids ON diploids.proteinId_1=seg_dups.proteinId_1 WHERE diploids.proteinId_1 IS NULL";
  sqlQueryWrite($sql_query,$unique_file);
}

######
# Gets the total number of FilteredModels for each scaffold
###########
sub mkScfFm {
  my $sql_query = "SELECT chrom,COUNT(chrom) AS count FROM FilteredModels1 GROUP BY chrom ORDER BY LENGTH(chrom),chrom";
  sqlQueryWrite($sql_query,$fm_file);
}

#######
# Gets the total length of each scaffold
#############
sub mkScfLen {
  my $sql_query = "SELECT chrom,(end-start) as length FROM scaffold";
  sqlQueryWrite($sql_query,$len_file);
}

######
# Reads in two-column data files with "scaffold" and some scaffold property
##############
sub storeData {
  my $file = shift @_;
  my $key_name = shift @_;
  open(my $in,"<",$file) or die "Can't open $file: $!\n";
  while(my $line = <$in>)
  {
    next if ($line !~ /^scaff/);
    chomp $line;
    my ($key,$val) = split(/\t/,$line);
    $data{$key}{$key_name} = $val;
  }
  close($in);
}

######
# Takes a single-column datafile and creates a hash 
#  where each value is 1
# There is probably a simpler way to do this
#################
sub simplerHash {
  my $file = shift @_;
  my %hash;
  open(my $in,"<",$file) or die "Can't open $file: $!\n";
  while (my $line = <$in>)
  {
    next if ($line =~ /^#/);
    chomp $line;
    $hash{$line} = 1;
  }
  close($in);
  return %hash;
}
