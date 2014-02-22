package Procera::Runner;
use Moose;
use warnings FATAL => 'all';

use Procera::WorkflowBuilder::DAG;

use Carp qw(confess);
use File::Spec qw();
use IO::File qw();
use Data::UUID qw();
use Procera::InputFile;
use Procera::Factory::Persistence;
use Procera::Factory::Storage;

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

has 'process_name' => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_process_name',
);


sub execute {
    my $self = shift;

    unless (scalar(@{$self->inputs}) > 0) {
        confess "No inputs files given to runner";
    }

    my $allocation = $self->_create_allocation;
    my $process_log_directory = File::Spec->join(
        $allocation->{absolute_path}, 'logs');

    my $workflow_name = $self->generate_workflow_name();
    my $process = $self->_persistence->create_process({
        allocation_id => $allocation->{id},
        workflow_name => $workflow_name,
        steps => [],
        created_results => [],
    });

    $logger->info('Launching Process ', $process,
        ' (', $process_log_directory, ')');

    my $inputs_file = $self->inputs_file($process);

    my $dag = Procera::WorkflowBuilder::DAG->from_xml_filename($self->workflow);
    $dag->name($workflow_name);
    $dag->log_dir($process_log_directory);

    _save_workflow($dag, $allocation->{absolute_path});
    _save_inputs($inputs_file, $allocation->{absolute_path});

    return $dag->execute($inputs_file->as_hash);
}

sub generate_workflow_name {
    my $self = shift;
    my $uuid = Data::UUID->new->create_b64;

    my $prefix;
    if ($self->has_process_name) {
        $prefix = $self->process_name;
    } else {
        $prefix = "Procera Process";
    }
    return "$prefix ($uuid)";
}

sub _create_allocation {
    my $self = shift;

    my $storage = Procera::Factory::Storage::create($self->_storage_type);
    return $storage->create_allocation(2048);
}

sub _persistence {
    my $self = shift;

    return Procera::Factory::Persistence::create($self->_persistence_type);
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

    $combined_inputs->set_contextual_input('test_name', _test_name());
    $combined_inputs->set_contextual_input('_process', $process);
    $combined_inputs->set_contextual_input('_persistence_type',
        _persistence_type());
    $combined_inputs->set_contextual_input('_storage_type', _storage_type());

    return $combined_inputs;
}

sub _test_name {
    return $ENV{GENOME_SOFTWARE_RESULT_TEST_NAME} || 'NONE';
}

sub _persistence_type {
    if ($ENV{AMBER_URL}) {
        return 'amber';
    } else {
        return 'memory';
    }
}

sub _storage_type {
    if ($ENV{ALLOCATION_URL}) {
        return 'allocation';
    } else {
        return 'tmp';
    }
}


1;
