package SystemTest::TestHelper;

use strict;
use warnings FATAL => 'all';

use File::Basename qw();
use File::Slurp qw();
use File::Spec qw();
use File::Temp qw();
use JSON qw();
use Test::More;

use Procera::Compiler;
use Procera::Runner;

sub run_system_test {
    my $test_file = shift;

    delete $ENV{AMBER_URL};  # Use memory persistence instead of amber
    my ($junk, $test_dir) = File::Basename::fileparse($test_file);

    my $output_directory = File::Temp::tempdir(CLEANUP => 1);
    compile($test_dir, $output_directory);

    my $outputs = run($test_dir, $output_directory);

    diff_outputs($test_dir, $outputs);

    done_testing;
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

    ok($cmd->execute, 'compile ran') || die;

    $ENV{GMSPATH} = $old_gms_path;
    shift @INC;
    return;
}

sub source_file {
    my $test_dir = shift;
    return File::Spec->join($test_dir, 'root.gms');
}

sub run {
    my ($test_dir, $output_directory) = @_;
    unshift @INC, File::Spec->join($test_dir, 'perl');

    my $runner = Procera::Runner->new(
        workflow => workflow_xml($output_directory),
        inputs => inputs($test_dir, $output_directory));

    ok($runner, 'instantiated runner') || die;


    $ENV{UR_DBI_NO_COMMIT} = 1;
    $ENV{NO_LSF} = 1;
    $ENV{WF_USE_FLOW} = 0;
    my $outputs = $runner->execute;


    shift @INC;
    return $outputs;
}

sub workflow_xml {
    my $output_directory = shift;

    return File::Spec->join($output_directory, 'workflow.xml');
}

sub inputs {
    my ($test_dir, $output_directory) = @_;

    return [
        File::Spec->join($output_directory, 'inputs.tsv'),
        File::Spec->join($test_dir, 'inputs.tsv'),
    ];
}

sub diff_outputs {
    my ($test_dir, $actual_outputs) = @_;

    my $expected_output = get_expected_output($test_dir);
    is_deeply($actual_outputs, $expected_output, 'got expected output');

    return;
}

sub get_expected_output {
    my $test_dir = shift;

    my $json_text = File::Slurp::read_file(expected_outputs($test_dir));
    ok($json_text, 'loaded expected_outputs') || die;
    my $json = JSON->new->allow_nonref;
    return $json->decode($json_text);
}

sub expected_outputs {
    my $test_dir = shift;
    return File::Spec->join($test_dir, 'expected-outputs.json');
}


1;
