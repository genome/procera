package Curator::TestHelper;

use strict;
use warnings FATAL => 'all';

use Data::Dump qw(pp);
use File::Copy qw();
use File::Slurp qw();
use File::Spec qw();
use File::Temp qw();
use Carp qw(confess);
use Test::More;

use Procera::Curator;
use TestHelper qw(diff_files);

my $SOURCE_PATH = 'Subject';

sub run {
    my (undef, $test_file) = caller;
    my ($junk, $test_dir) = File::Basename::fileparse($test_file);

    unshift @INC, File::Spec->join($test_dir, 'perl');
    my $old_gms_path = $ENV{GMSPATH};
    $ENV{GMSPATH} = File::Spec->join($test_dir, 'definitions');

    curate($test_dir, $SOURCE_PATH);

    $ENV{GMSPATH} = $old_gms_path;
    shift @INC;

    done_testing();
}

sub curate {
    my ($test_dir, $source_path) = @_;

    my $curator = Procera::Curator->new(source_path => $source_path);
    my $created_report = write_report($curator);
    my $expected_report = File::Spec->join($test_dir, 'expected_report.txt');
    diff_files($created_report, $expected_report, "Found the report as expected");
}

sub write_report {
    my $curator = shift;

    my $output_filename = File::Spec->join(File::Temp::tempdir(CLEANUP => 1),
        'report.txt');
    my $output_fh = IO::File->new($output_filename, 'w');
    printf $output_fh "Inputs:\n%s\nParams:\n%s\nOutputs:\n%s\n",
        pp($curator->inputs),
        pp($curator->params),
        pp($curator->outputs);
    $output_fh->close();
    return $output_filename;
}

1;
