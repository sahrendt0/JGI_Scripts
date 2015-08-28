#!/usr/bin/perl
# Script: checkRegions.pl
# Description:  
# Author: Steven Ahrendt
# email: sahrendt0@gmail.com
# Date: 08.19.2015
##################################
use warnings;
use strict;
use Getopt::Long;
use lib '/rhome/sahrendt/Scripts';

#####-----Global Variables-----#####
my $input;
my ($help,$verb);
my $sim = 0; # similarity threshold: number of bases difference 
             # between start and/or stop 

GetOptions ('i|input=s' => \$input,
            'sim=i'     => \$sim,
            'h|help'   => \$help,
            'v|verbose' => \$verb);
my $usage = "Usage: checkRegions.pl -i input\n\n";
die $usage if $help;
die "No input.\n$usage" if (!$input);

#####-----Main-----#####
open(my $in,"<",$input) or die "Can't open $input: $!\n";
my @file = <$in>;
close($in);
chomp @file;

my @unique; # unique regions

for(my $i=0;$i<(scalar @file)-1; $i++)
{
  my $j = $i+1; # next index
  my $line = $file[$i];
  my ($start1,$end1,$scf1,$src1) = split(/\t/,$line);
  my ($start2,$end2,$scf2,$src2) = split(/\t/,$file[$j]);
  if(!isSame($start1,$start2) && !isSame($end1,$end2))
  {
    #print "$start1 $start2 :: $end1 $end2\t";
    #print isSame($start1,$start2),"\t",isSame($end1,$end2),"\t";
    print $line,"\n";
  }
  else
  {
    $i++;
  }
}

warn "Done.\n";
exit(0);

#####-----Subroutines-----#####
sub isSame {
  my ($a,$b) = @_;
  my $isSame = 0;
  if(abs($a-$b) <= $sim)
  {
    $isSame = 1;
  }
  return $isSame;
}
