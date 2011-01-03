use strict;
use warnings;
use FindBin;
use File::Spec;
use Algorithm::Clustering::BiSection;

my $gzip_file = File::Spec->catfile( $FindBin::Bin, "data", "sample.txt.gz" );
`gzip -d $gzip_file` if -e $gzip_file;

my $clustering_tool = Algorithm::Clustering::BiSection->new;
my $one_huge_cluster = $clustering_tool->read_file( File::Spec->catfile($FindBin::Bin, "data", "sample.txt"));
$clustering_tool->bisection($one_huge_cluster);