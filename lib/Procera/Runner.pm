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
    my $username = getpwuid( $< );
    my $process_content = {
        username => $username,
        allocation_id => $allocation->{id},
        workflow_name => $workflow_name,
        source_path => $self->process_name,
        status => 'running',
    };
    my $process_uri = $self->_persistence->create_process($process_content);

    $logger->info('Launching Process ', $process_uri,
        ' (', $process_log_directory, ')');

    my $inputs_file = $self->inputs_file($process_uri);

    my $dag = Procera::WorkflowBuilder::DAG->from_xml_filename($self->workflow);
    $dag->name($workflow_name);
    $dag->log_dir($process_log_directory);

    _save_workflow($dag, $allocation->{absolute_path});
    _save_inputs($inputs_file, $allocation->{absolute_path});

    my $outputs = eval{$dag->execute($inputs_file->as_hash)};
    my $error = $@;
    $self->update_status($error, $process_content, $process_uri);

    if ($error) {
        die "Error with process ($process_uri): $error";
    } else {
        return $outputs;
    }
}

sub update_status {
    my ($self, $error, $process_content, $process_uri) = @_;

    if ($error) {
        $process_content->{status} = 'crashed';
    } else {
        $process_content->{status} = 'succeeded';
    }
    $self->_persistence->update_process(
        process_uri => $process_uri,
        content => $process_content,
    );
    return;
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
