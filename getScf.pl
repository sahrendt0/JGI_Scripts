#!/usr/bin/perl
# Script: getScf.pl
# Description: Gets a specific scaffold from MySQL database
# Author: Steven Ahrendt
# email: sahrendt0@gmail.com
# Date: 8.17.15
##################################
use warnings;
use strict;
use Getopt::Long;
#use lib '~/Scripts';

#####-----Global Variables-----#####
my $user="sahrendt";
my $host="gpdb03.nersc.gov";
my $pass='m0rn$T4R';
my ($db,$table);
my ($help,$verb);
my $scf;
GetOptions ('d|database=s' => \$db,
            't|table=s'    => \$table,
            'u|user=s'     => \$user,
            'host=s'       => \$host,
            'scf=s'        => \$scf,
            'h|help'       => \$help,
            'v|verbose'    => \$verb);
my $usage = "Usage getScf.pl -d database -t table -s scf";
die $usage if $help;

#####-----Main-----#####
my $outfile="$scf.fasta";
print `mysql -u $user -h $host --password=$pass $db -e 'SELECT seq AS ">$scf" FROM $table WHERE scaffold="$scf"' > $outfile`;

#####-----Subroutines-----#####
sub getMysqlPass {
  my $pass;
  open(my $cnf,"<","/global/home/s/sahrendt/.my.cnf") or die "Can't open MySQL config file: $!\n";
  while(my $line = <$cnf>)
  {
    next if ($line !~ /^password/);
    $pass = (split(/'/,$line))[1];
  }
  close($cnf);
  return $pass;
}
