package Procera::Tool::Detail::Base;
use Moose;
use warnings FATAL => 'all';

use Amber::Factory::ManifestAllocation;
use Amber::Manifest::Writer;
use Amber::ProcessStep;
use Amber::Result;
use Amber::Translator;
use File::Path qw();
use File::Temp qw();
use Log::Log4perl qw();
use Memoize qw();
use Procera::Tool::Detail::AttributeSetter;
use Procera::Tool::Detail::Contextual;

with 'Procera::WorkflowCompatibility::Role';


Log::Log4perl->easy_init($Log::Log4perl::DEBUG);

my $logger = Log::Log4perl->get_logger();


has test_name => (
    is => 'rw',
    isa => 'Str',
    traits => ['Param', 'Contextual'],
    required => 1,
);
has _process => (
    is => 'rw',
    traits => ['Param', 'Contextual'],
    required => 1,
);
has _step_label => (
    is => 'rw',
    isa => 'Str',
    traits => ['Param', 'Contextual'],
    required => 1,
);

has _raw_inputs => (
    is => 'rw',
    isa => 'HashRef',
);
has _original_working_directory => (
    is => 'rw',
    isa => 'Str',
);
has _workspace_path => (
    is => 'rw',
    isa => 'Str',
);


sub inputs {
    my $class = shift;

    return map {$_->name} grep {$_->does('Input')}
        $class->meta->get_all_attributes;
}
Memoize::memoize('inputs');

sub outputs {
    my $class = shift;

    return map {$_->name} grep {$_->does('Output')}
        $class->meta->get_all_attributes;
}
Memoize::memoize('outputs');

sub params {
    my $class = shift;

    return map {$_->name} grep {$_->does('Param')}
        $class->meta->get_all_attributes;
}
Memoize::memoize('params');


sub shortcut {
    my $self = shift;

    $logger->info("Attempting to shortcut ", ref $self,
        " with test name (", $self->test_name, ")");

    my $result = Amber::Result->lookup(inputs => $self->_inputs_as_hashref,
        tool_class_name => ref $self, test_name => $self->test_name);

    if ($result) {
        $logger->info("Found matching result with lookup hash (",
            $result->lookup_hash, ")");
        $self->_set_outputs_from_result($result);

        $self->_create_process_step($result);
        return 1;

    } else {
        $logger->info("No matching result found for shortcut");
        return;
    }
}

sub _inputs_as_hashref {
    my $self = shift;

    my %inputs;
    for my $input_name ($self->_non_contextual_input_names) {
        $inputs{$input_name} = $self->$input_name;
    }

    return \%inputs;
}

sub _non_contextual_input_names {
    my $self = shift;

    return $self->inputs, $self->_non_contextual_params;
}

sub _non_contextual_params {
    my $self = shift;
    return map {$_->name} grep {$_->does('Param') && !$_->does('Contextual')}
        $self->meta->get_all_attributes;
}
Memoize::memoize('_non_contextual_params');


sub _property_names {
    my $self = shift;

    return map {$_->property_name} $self->__meta__->properties(@_);
}

sub _set_outputs_from_result {
    my ($self, $result) = @_;

    my $result_outputs = $result->outputs;
    for my $output_name (keys %$result_outputs) {
        $self->$output_name($result_outputs->{$output_name});
    }

    return;
}

sub _create_process_step {
    my ($self, $result) = @_;

    $self->_translate_inputs('_process', '_step_label');
    Amber::ProcessStep->create(process => $self->_process, result => $result,
        label => $self->_step_label);

    return;
}

sub _translate_inputs {
    my $self = shift;

    my $translator = Amber::Translator->new();
    for my $input_name (@_) {
        $self->$input_name($translator->resolve_scalar_or_url($self->$input_name));
    }

    return;
}


sub execute {
    my $self = shift;

    $self->_setup;
    $logger->info("Process id: ", $self->_process->id);

    eval {
        $self->execute_tool;
    };

    my $error = $@;
    if ($error) {
        unless ($ENV{GENOME_SAVE_WORKSPACE_ON_FAILURE}) {
            $self->_cleanup;
        }
        die $error;

    } else {
        $self->_save;
        $self->_cleanup;
    }

    return 1;
}

sub _setup {
    my $self = shift;

    $self->_setup_workspace;
    $self->_cache_raw_inputs;
    $self->_translate_inputs($self->inputs, $self->_contextual_params);

    return;
}

sub _setup_workspace {
    my $self = shift;

    $self->_workspace_path(File::Temp::tempdir(CLEANUP => 1));
    $self->_original_working_directory(Cwd::cwd());
    chdir $self->_workspace_path;

    return;
}

sub _cache_raw_inputs {
    my $self = shift;

    $self->_raw_inputs($self->_inputs_as_hashref);

    return;
}

sub _contextual_params {
    my $self = shift;
    return map {$_->name} grep {$_->does('Contextual')}
        $self->meta->get_all_attributes;
}


sub execute_tool {
    die 'Abstract method';
}

sub _cleanup {
    my $self = shift;

    chdir $self->_original_working_directory;
    File::Path::rmtree($self->_workspace_path);

    return;
}

sub _save {
    my $self = shift;

    $self->_verify_outputs_in_workspace;

    my $allocation = $self->_save_outputs;
    $self->_translate_outputs($allocation);
    my $result = $self->_create_checkpoint($allocation);
    $self->_create_process_step($result);

    return;
};

sub _verify_outputs_in_workspace { }

sub _save_outputs {
    my $self = shift;

    $self->_create_output_manifest;
    my $allocation = Amber::Factory::ManifestAllocation::from_manifest(
        $self->_workspace_manifest_path);

    $logger->info("Saved outputs from tool '", ref $self,
        "' to allocation (", $allocation->id, ")");
    $allocation->reallocate;

    return $allocation;
}

sub _create_output_manifest {
    my $self = shift;

    my $writer = Amber::Manifest::Writer->create(
        manifest_file => $self->_workspace_manifest_path);
    for my $output_name ($self->_saved_file_names) {
        my $path = $self->$output_name || '';
        if (-e $path) {
            $writer->add_file(path => $path, kilobytes => -s $path,
                tag => $output_name);
        } else {
            confess sprintf("Failed to save output '%s'", $path);
        }
    }
    $writer->save;

    return;
}

sub _workspace_manifest_path {
    my $self = shift;
    return File::Spec->join($self->_workspace_path, 'manifest.xml');
}

sub _saved_file_names {
    my $class = shift;

    return map {$_->name} grep {$_->does('Output') && $_->save}
        $class->meta->get_all_attributes;
}

sub _translate_outputs {
    my ($self, $allocation) = @_;

    for my $output_file_name ($self->_saved_file_names) {
        $self->$output_file_name(
            _translate_output($allocation->id, $output_file_name)
        );
    }

    return;
}

sub _translate_output {
    my ($allocation_id, $tag) = @_;

    return sprintf('gms:///data/%s?tag=%s', $allocation_id, $tag);
}

sub _create_checkpoint {
    my ($self, $allocation) = @_;

    my $result = Amber::Result->create(tool_class_name => ref $self,
        test_name => $self->test_name, allocation => $allocation,
        owner => $self->_process);

    for my $input_name ($self->_non_contextual_input_names) {
        $result->add_input(name => $input_name,
            value => $self->_raw_inputs->{$input_name});
    }

    for my $output_name ($self->outputs) {
        $result->add_output(name => $output_name,
            value => $self->$output_name);
    }

    $result->update_lookup_hash;

    return $result;
}



no Procera::Tool::Detail::AttributeSetter;
__PACKAGE__->meta->make_immutable;
