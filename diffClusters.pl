#!/usr/bin/perl
# Script: diffClusters.pl
# Description: Given two organisms, find and report clusters which are different 
# Author: Steven Ahrendt
# email: sahrendt0@gmail.com
# Date: 08.21.2015
##################################
use warnings;
use strict;
use Getopt::Long;
use lib '/global/homes/s/sahrendt/Scripts';

#####-----Global Variables-----#####
my $input;
my ($org_list,@orgs);
my %clusters;
my ($help,$verb);

GetOptions ('i|input=s' => \$input,
            'org=s'     => \$org_list,
            'h|help'    => \$help,
            'v|verbose' => \$verb);
my $usage = "Usage: diffClusters.pl -i cluster_file --org organism_1,organism_2 [-v]\nGiven two organisms, find and report clusters which are different\niDefault prints counts only. -v(erbose) option prints ids of cluster members, comma-delimited\n";
die $usage if $help;
die "No input.\n$usage" if (!$input);
@orgs = split(/,/,$org_list);
die "Incorrect format of organism list. Please specify two (2) comma-delimited organisms.\n" if (scalar @orgs != 2);

#####-----Main-----#####
## Read cluster list
open(my $fh,"<",$input) or die "Can't open $input: $1\n";
my $lc=1; #cluster number
while(my $line = <$fh>)
{
  chomp $line;
  my @models=split(/\t/,$line);
  foreach my $model (@models)
  {
    my($org_name,$table,$id) = split(/:/,$model);
    $clusters{$lc}{$org_name}{$id} = $table;
  }
  $lc++;
}

close($fh);

## Output
print "#ClusterID\t$orgs[0]\t$orgs[1]\n";
for(my $c=1;$c<$lc;$c++)
{
  my (@keys1,$hits1,@keys2,$hits2);
  @keys1 = keys %{$clusters{$c}{$orgs[0]}} if(exists $clusters{$c}{$orgs[0]});
  $hits1 = scalar @keys1;
  @keys2 = keys %{$clusters{$c}{$orgs[1]}} if(exists $clusters{$c}{$orgs[1]});
  $hits2 = scalar @keys2;
  if($hits1 != $hits2)
  {
    if(!$verb)
    {
      print "$c\t$hits1\t$hits2\n";
    }
    else
    {
      my ($ids1,$ids2) = ("NA","NA");
      if($hits1 != 0)
      {
        $ids1 = join(",",@keys1);
      }
      if($hits2 != 0)
      {
        $ids2 = join(",",@keys2);
      }
      print "$c\t$ids1\t$ids2\n";
    }
  }
}

warn "Done.\n";
exit(0);

#####-----Subroutines-----#####
