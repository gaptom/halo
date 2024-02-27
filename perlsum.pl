#!/usr/bin/perl
use strict;
use warnings;
use Fcntl ':flock', 'O_RDONLY', 'O_WRONLY', 'O_CREAT'; # Example for importing multiple constants

# Open the log file
sub sum1 {
my ($filename,$patter) = @_;
#open(my $fh, '<', $filename) or die "Could not open file '$filename' $!";
sysopen(my $fh, $filename, O_RDONLY) or die "Could not open file '$filename' $!";

# Initialize total duration
my $total = 0;

# Iterate over each line of the file
while (my $row = <$fh>) {
  chomp $row;
  
  # Match the duration pattern and extract the number of seconds
  if ($row =~ /$patter/) {
    # Add the duration to the total
    $total += $1;
    #print "$total"."\n";
  }
}

# Close the file handle
close($fh);
 return $total;
}
my  $total_duration = 0;
my $file = '';
my $dir = '/home/postgres/test/';
if (@ARGV) {
    $file = $ARGV[0];  # 打印第一个命令行参数
} else {
    print "No arguments provided.\n";
}

my $dirfile = $dir.$file.'.txt';
my $patter = 'qr/\b(\d+(?:\.\d+)?)\s*(seconds|secs)\b/';
$total_duration += sum1($dirfile,$patter);

print "\n$total_duration\n";
