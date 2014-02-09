package TestHelper;

use Test::More;
use File::Copy qw();
use File::Slurp qw();
use Carp qw(confess);

use Exporter 'import';
our @EXPORT_OK = qw(
    diff_files
);

sub diff_files {
    my ($got, $expected, $statement) = @_;

    my $got_text = File::Slurp::read_file($got);
    my $expected_text = File::Slurp::read_file($expected);
    is_deeply($got_text, $expected_text, $statement);

    update_test_data($got, $expected);
}

sub update_test_data {
    my ($got, $expected) = @_;

    if ($ENV{UPDATE_TEST_DATA}) {
        my $result = File::Copy::copy($got, $expected);
        if ($result) {
            print "Copied file ($got) to ($expected)\n";
        } else {
            confess "failed to copy file ($got) to ($expected)";
        }
    }
}

