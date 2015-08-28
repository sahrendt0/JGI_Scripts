#!/usr/bin/perl
# Script: id2fulltax.pl
# Description: Print full taxonomy listing by using taxid  
# Author: Steven Ahrendt
# email: sahrendt0@gmail.com
# Date: 8.24.2015
##################################
use warnings;
use strict;
use Getopt::Long;
use lib '~/Scripts';
use SeqAnalysis;
use Data::Dumper;

#####-----Global Variables-----#####
my $input;
my ($help,$verb);
my @ranks = qw(kingdom phylum class order family genus species);
my $user_ranks;

GetOptions ('i|input=s' => \$input,
            'h|help'   => \$help,
            'v|verbose' => \$verb,
            'ranks=s'     => \$user_ranks);
my $usage = "Usage: test_tax.pl -i input [--ranks]\n\n";
die $usage if $help;
die "No input.\n$usage" if (!$input);

#####-----Main-----#####
@ranks = split(/,/,$user_ranks) if $user_ranks;
warn join("-",@ranks),"\n" if $verb;
my $tax_db = initNCBI();
open(IN,"<",$input) or die "Can't open $input: $!\n";
while(my $line = <IN>)
{
  chomp $line;
  my $id = (split(/\t/,$line))[1];
  my $hash = getTaxonomybyID($tax_db,$id);
#  print Dumper $hash;
  $line =~ s/ /\t/;
  print $line,"\t";
  printTaxonomy($hash,\@ranks,"",$id);
}

close(IN);
warn "Done.\n";
exit(0);

#####-----Subroutines-----#####
