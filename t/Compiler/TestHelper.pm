package Compiler::TestHelper;

use strict;
use warnings FATAL => 'all';

use Carp qw(confess);
use Test::More;
use File::Spec qw();
use File::Temp qw();
use File::Basename qw();

use Genome::Utility::Test qw(compare_ok);

use Procera::Compiler;


sub source_file {
    my $test_dir = shift;
    return File::Spec->join($test_dir, 'root.gms');
}

sub compiler_expected_result {
    my $test_dir = shift;
    return File::Spec->join($test_dir, 'compiler-output');
}


sub compile {
    my ($test_dir, $output_directory) = @_;

    unshift @INC, File::Spec->join($test_dir, 'perl');
    my $old_gms_path = $ENV{GMSPATH};
    $ENV{GMSPATH} = File::Spec->join($test_dir, 'definitions');

    my $cmd = Procera::Compiler->new(
        'input-file' => source_file($test_dir),
        'output-directory' => $output_directory,
    );

    ok($cmd->execute, 'command ran') || die;

    $ENV{GMSPATH} = $old_gms_path;
    shift @INC;
    return;
}

my @_FILENAMES = (
    'workflow.xml',
    'inputs.tsv'
);
sub update_directory {
    my ($old, $new) = @_;

    for my $filename (@_FILENAMES) {
        my $result = File::Copy::copy(
            File::Spec->join($new, $filename),
            File::Spec->join(compiler_expected_result($old), $filename),
        );
        confess 'failed to copy file' unless $result;
    }

    return;
}

sub diff_directories {
    my ($test_dir, $actual) = @_;
    my $expected = compiler_expected_result($test_dir);
    for my $filename (@_FILENAMES) {
        my $expected_path = File::Spec->join($expected, $filename);
        my $actual_path = File::Spec->join($actual, $filename);
        ok(-e $expected_path, "found expected file: $expected_path") or next;
        ok(-e $actual_path, "found actual file: $actual_path") or next;

        compare_ok(
            $expected_path,
            $actual_path,
            sprintf('%s compares ok', $filename),
            filters => [
                qr(STEP_LABEL_[^\t]*),
            ],
        ) or print `diff -u $expected $actual_path` . "\n";

    }

    return;
}

sub should_update_directory {
    return $ENV{UPDATE_TEST_DATA} || undef;
}

sub run_system_test {
    my $test_file = shift;

    my ($junk, $test_dir) = File::Basename::fileparse($test_file);

    my $output_directory = File::Temp::tempdir(CLEANUP => 1);
    compile($test_dir, $output_directory);

    diff_directories($test_dir, $output_directory);

    if (defined(should_update_directory())) {
        update_directory(
            $test_dir, $output_directory);
    }
    done_testing();
}
