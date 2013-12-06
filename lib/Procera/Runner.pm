package Procera::Runner;
use Moose;
use warnings FATAL => 'all';

use UR;
use Genome::WorkflowBuilder::DAG;

use Carp qw(confess);
use IO::File qw();
use Procera::InputFile;
use Amber;
use Amber::Factory::Process;

use Log::Log4perl qw();

my $logger = Log::Log4perl->get_logger();


has 'workflow' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has 'inputs' => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    required => 1,
);


sub execute {
    my $self = shift;

    unless (scalar(@{$self->inputs}) > 0) {
        confess "No inputs files given to runner";
    }

    my $process = Amber::Factory::Process::new();
    $logger->info('Launching Process ', $process->hyphenated_id,
        ' (', $process->log_directory, ')');

    my $inputs_file = $self->inputs_file($process);

    my $dag = Genome::WorkflowBuilder::DAG->from_xml_filename($self->workflow);
    $dag->name($process->workflow_name);
    $dag->log_dir($process->log_directory);

    $process->save_workflow($dag);
    $process->save_inputs($inputs_file);

    UR::Context->commit;
    return $dag->execute($inputs_file->as_hash);
}

sub inputs_file {
    my ($self, $process) = @_;

    my $combined_inputs = Procera::InputFile->new;
    for my $input_path (@{$self->inputs}) {
        my $input_file = Procera::InputFile->create_from_filename($input_path);
        $combined_inputs->update($input_file);
    }

    $combined_inputs->set_test_name(_test_name());
    $combined_inputs->set_process($process->url);

    return $combined_inputs;
}

sub _test_name {
    return $ENV{GENOME_SOFTWARE_RESULT_TEST_NAME} || 'NONE';
}


1;
