#!/usr/bin/perl
# Script: getHitSrc.pl
# Description: Gets source organism (and taxonomy) for top blast hits in FM1
# Author: Steven Ahrendt
# email: sahrendt0@gmail.com
# Date: 08.27.2015
##################################
use warnings;
use strict;
use Getopt::Long;
use Data::Dumper;
use lib '/global/homes/s/sahrendt/Scripts';
use SeqAnalysis;

#####-----Global Variables-----#####
my $input;
my $NCBI_TAX = initNCBI("entrez");
#print Dumper $NCBI_TAX;
my ($help,$verb);

GetOptions ('i|input=s' => \$input,
            'h|help'   => \$help,
            'v|verbose' => \$verb);
my $usage = "Usage: getHitSrc.pl -i input\n\n";
die $usage if $help;
die "No input.\n$usage" if (!$input);

#####-----Main-----#####
open(my $in, "<", $input) or die "Can't open $input: $!\n";
my $no_hit=0;
while(my $line = <$in>)
{
  next if ($line =~ /^#/);
  if($line !~ /No hit/)
  {
    chomp $line;
    my @data = split(/ /,$line);
    my $range = shift @data;
    my $strand = shift @data;
    my $acc = shift @data;
    my $hcov = pop @data;
    my $mcov = pop @data;
    my $iden = pop @data;
    my $desc = join(" ",@data);
    $desc =~ /\[(.*?)\]/;
    my $src_org = $1;
    $src_org =~ s/\&nbsp\;//g;
    my $tax = getTaxonomybySpecies($NCBI_TAX,$src_org);
    my %tax_hash;
    $tax_hash{$src_org} = $tax;
    #print Dumper \%tax_hash;
    printTaxonomy(\%tax_hash,\@STD_TAX,"","$src_org");
  }
  else
  {
    $no_hit++;
  }
}
close($in);
warn "Done.\n";
exit(0);

#####-----Subroutines-----#####
