package Procera::Runner;
use Moose;
use warnings FATAL => 'all';

use UR;
use Genome::WorkflowBuilder::DAG;

use Carp qw(confess);
use File::Spec qw();
use IO::File qw();
use Procera::InputFile;
use Procera::Persistence;
use Procera::Storage;

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

    my $storage = Procera::Storage->new;
    my $allocation = $storage->create_allocation(2048);
    my $process_log_directory = File::Spec->join(
        $allocation->absolute_path, 'logs');

    my $persistence = Procera::Persistence->new(base_url => $self->_amber_url);
    my $process = $persistence->create_process({
        allocation_id => $allocation->id,
        steps => [],
        created_results => [],
    });

    $logger->info('Launching Process ', $process->{resource_uri},
        ' (', $process_log_directory, ')');

    my $inputs_file = $self->inputs_file($process);

    my $dag = Genome::WorkflowBuilder::DAG->from_xml_filename($self->workflow);
    $dag->name(_workflow_name($process));
    $dag->log_dir($process_log_directory);

    _save_workflow($dag, $allocation->absolute_path);
    _save_inputs($inputs_file, $allocation->absolute_path);

    UR::Context->commit;
    return $dag->execute($inputs_file->as_hash);
}

sub _amber_url {
    return $ENV{AMBER_URL} || 'http://localhost:8000';
}

sub _workflow_name {
    my $process = shift;

    return sprintf("Process %s", $process->{resource_uri});
}

sub _save_workflow {
    my ($dag, $path) = @_;
    File::Slurp::write_file(File::Spec->join($path, 'workflow.xml'),
        $dag->get_xml);
    return;
}

sub _save_inputs {
    my ($input_file, $path) = @_;

    my $file = IO::File->new(File::Spec->join($path, 'inputs.tsv'), 'w');
    $input_file->write($file);
    $file->close;

    return;
}

sub inputs_file {
    my ($self, $process) = @_;

    my $combined_inputs = Procera::InputFile->new;
    for my $input_path (@{$self->inputs}) {
        my $input_file = Procera::InputFile->create_from_filename($input_path);
        $combined_inputs->update($input_file);
    }

    $combined_inputs->set_test_name(_test_name());
    $combined_inputs->set_process($process->{resource_uri});

    return $combined_inputs;
}

sub _test_name {
    return $ENV{GENOME_SOFTWARE_RESULT_TEST_NAME} || 'NONE';
}


1;
