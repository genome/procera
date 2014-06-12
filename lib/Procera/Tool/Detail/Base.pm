package Procera::Tool::Detail::Base;
use Moose;
use warnings FATAL => 'all';

use Procera::Factory::Persistence;
use Procera::Factory::Storage;
use Procera::Translator;
use File::Path qw();
use File::Temp qw();
use IO::File qw();
use Log::Log4perl qw();
use Memoize qw();
use Procera::Tool::Detail::AttributeSetter;
use Procera::Tool::Detail::Contextual;
use Params::Validate qw(validate_pos);

with 'Procera::WorkflowCompatibility::Role';


Log::Log4perl->easy_init($Log::Log4perl::DEBUG);

my $logger = Log::Log4perl->get_logger();


has test_name => (
    is => 'ro',
    isa => 'Str',
    traits => ['Param', 'Contextual'],
    required => 1,
);
has _process => (
    is => 'ro',
    traits => ['Param', 'Contextual'],
    required => 1,
);
has _step_label => (
    is => 'ro',
    isa => 'Str',
    traits => ['Param', 'Contextual'],
    required => 1,
);
has _persistence_type => (
    is => 'ro',
    isa => 'Str',
    traits => ['Param', 'Contextual'],
    required => 1,
);
has _storage_type => (
    is => 'ro',
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

sub lsf_resource {
    return;
}

sub version {
    return "0.0.1";
}

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

sub saved_outputs {
    my $class = shift;

    return map {$_->name} grep {$_->does('Output') && $_->save}
        $class->meta->get_all_attributes;
}
Memoize::memoize('saved_outputs');

sub params {
    my $class = shift;

    return map {$_->name} grep {$_->does('Param')}
        $class->meta->get_all_attributes;
}
Memoize::memoize('params');

sub non_contextual_params {
    my $class = shift;
    return map {$_->name} grep {$_->does('Param') && !$_->does('Contextual')}
        $class->meta->get_all_attributes;
}
Memoize::memoize('non_contextual_params');

sub non_contextual_inputs {
    my $class = shift;

    return $class->inputs, $class->non_contextual_params;
}
Memoize::memoize('non_contextual_inputs');


sub is_array {
    my ($class, $name) = validate_pos(@_, 1, 1);

    my $attribute = $class->meta->find_attribute_by_name($name);
    unless ($attribute) {
        confess sprintf("Tool (%s) doesn't have an attribute named (%s)",
            ref $class, $name);
    }
    if ($attribute->array) {
        return 1;
    } else {
        return 0;
    }
}


sub shortcut {
    my $self = shift;

    $logger->info("Process uri (", $self->_process, ")");
    $logger->info("Attempting to shortcut (", ref $self,
        ") with test name (", $self->test_name, ")");

    my $tool = $self->_persistence->register_tool(
        source_path => ref $self,
        version => $self->version,
    );

    my $result = $self->_persistence->get_result(
        inputs => $self->_inputs_as_hashref,
        source_path => ref $self,
        version => $self->version,
        test_name => $self->test_name,
    );

    if ($result) {
        $logger->info("Found matching result (", $result->{resource_uri}, ")");
        $self->_set_outputs_from_result($result);

        $logger->info("Adding process-step (", $self->_step_label, ")");
        $self->_persistence->add_step_to_process(
            label => $self->_step_label,
            process => $self->_process,
            result => $result->{resource_uri},
        );

        return 1;

    } else {
        $logger->info("No matching result found for shortcut");
        return;
    }
}

sub _persistence {
    my $self = shift;
    return Procera::Factory::Persistence::create($self->_persistence_type);
}

sub _inputs_as_hashref {
    my $self = shift;

    my %inputs;
    for my $input_name ($self->non_contextual_inputs) {
        $inputs{$input_name} = $self->$input_name;
    }

    return \%inputs;
}

sub _property_names {
    my $self = shift;

    return map {$_->property_name} $self->__meta__->properties(@_);
}

sub _set_outputs_from_result {
    my ($self, $result) = @_;

    my $result_outputs = $result->{outputs};
    for my $output_name (keys %$result_outputs) {
        $self->$output_name($result_outputs->{$output_name});
    }

    return;
}

sub _translate_inputs {
    my $self = shift;

    my $translator = Procera::Translator->new(
        persistence => $self->_persistence,
        storage => $self->_storage,
    );
    for my $input_name (@_) {
        if ($self->is_array($input_name)) {
            $self->$input_name(
                [map {$translator->resolve_scalar_or_url($_)} @{$self->$input_name}]
            );
        } else {
            $self->$input_name($translator->resolve_scalar_or_url(
                    $self->$input_name));
        }
        $self->$input_name($translator->resolve_scalar_or_url(
                $self->$input_name));
    }

    return;
}


sub execute {
    my $self = shift;

    $logger->info("Process uri (", $self->_process, ")");
    $logger->info("Executing (", ref $self, ") with test name (",
            $self->test_name, ")");

    $self->_setup;

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
    $self->_translate_inputs($self->inputs);
    $self->_symlink_inputs;
    $self->_reset_inputs_with_locations;

    return;
}


sub _setup_workspace {
    my $self = shift;

    $self->_workspace_path(File::Temp::tempdir(CLEANUP => 1));
    $self->_original_working_directory(Cwd::cwd());
    chdir $self->_workspace_path;

    $logger->info("Setup workspace at (", $self->_workspace_path, ")");

    return;
}

sub _cache_raw_inputs {
    my $self = shift;

    $self->_raw_inputs($self->_inputs_as_hashref);

    return;
}

sub _symlink_inputs {
    my $self = shift;

    for my $input ($self->_inputs_with_locations) {
        my $name = $input->name;
        if (-e $self->$name) {
            _symlink_into_workspace($self->$name, $input->location);
        } else {
            Carp::confess(sprintf("Could not symlink input (%s) into workspace"
                    . " because source (%s) does not exist.",
                    $name, $self->$name));
        }
    }

    return;
}

sub _reset_inputs_with_locations {
    my $self = shift;

    for my $input ($self->_inputs_with_locations) {
        my $name = $input->name;
        $self->$name($input->location);
    }

    return;
}

sub _inputs_with_locations {
    my $class = shift;
    return grep {$_->has_location} grep {$_->does('Input')}
        $class->meta->get_all_attributes;
}

sub _symlink_into_workspace {
    my ($source_path, $relative_dest_path) = @_;

    if (_is_absolute($relative_dest_path)) {
        Carp::confess(sprintf("Got absolute path (%s) for input location.  "
                . "Relative path required.", $relative_dest_path));
    }

    $logger->info("Symlinking (", $source_path, ") into the workspace as (",
            $relative_dest_path, ")");
    _make_path($relative_dest_path);
    symlink $source_path, $relative_dest_path;

    return;
}

sub _make_path {
    my $full_path = shift;

    my ($file, $path) = File::Basename::fileparse($full_path);
    File::Path::make_path($path);

    return;
}

sub _is_absolute {
    my $path = shift;

    return File::Spec->rel2abs($path) eq $path;
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

    $self->_verify_saved_outputs_in_workspace;

    if ($self->_saved_file_names) {
        my $allocation_id = $self->_storage->save_files($self->_saved_file_names);
        my $fileset = $self->_create_fileset_for_outputs($allocation_id);
        $self->_set_output_uris($fileset);
    }

    $self->_create_result;

    return;
};

sub _saved_file_names {
    my $self = shift;

    my @result;
    for my $output_name ($self->saved_outputs) {
        if ($self->is_array($output_name)) {
            push @result, @{$self->$output_name};
        } else {
            push @result, $self->$output_name;
        }
    }
    return @result;
}

sub _verify_saved_outputs_in_workspace {
    my $self = shift;

    for my $filename ($self->_saved_file_names) {
        unless (-f $filename) {
            Carp::confess(sprintf("Tool (%s) has an output that is set to be"
                    . " saved but is not a file (%s)",
                    ref $self, $filename));
        }
    }
}

sub _create_fileset_for_outputs {
    my ($self, $allocation_id) = @_;

    return $self->_persistence->create_fileset(
        {
            files => [$self->_file_info],
            allocation_id => $allocation_id,
        }
    );
}

sub _file_info {
    my $self = shift;

    my @result;
    for my $filename ($self->_saved_file_names) {
        push @result, $self->_file_info_element($filename);
    }

    return @result;
}

sub _file_info_element {
    my ($self, $filename) = @_;

    return {
        path => $filename,
        size => -s $filename,
        md5 => _md5sum($filename),
    };
}

sub _md5sum {
    my $path = shift;

    my $context = Digest::MD5->new;
    my $fh = IO::File->new($path, 'r');
    $context->addfile($fh);
    return $context->hexdigest;
}

sub _storage {
    my $self = shift;

    return Procera::Factory::Storage::create($self->_storage_type);
}

sub _set_output_uris {
    my ($self, $fileset) = @_;

    my %uri_map = $self->_get_uri_map($fileset);
    for my $output_name ($self->saved_outputs) {
        if ($self->is_array($output_name)) {
            $self->$output_name([
                map {$uri_map{$_}} @{$self->$output_name}
            ]);
        } else {
            $self->$output_name($uri_map{$self->$output_name});
        }
    }

    return;
}

sub _get_uri_map {
    my ($self, $fileset) = validate_pos(@_, 1, 1);

    my %result;
    for my $file (@{$fileset->{files}}) {
        $result{$file->{path}} = $file->{resource_uri};
    }
    return %result;
}

sub _create_result {
    my $self = shift;

    $logger->info("Creating result and adding process-step (",
            $self->_step_label, ")");

    my $tool = $self->_persistence->register_tool(
        source_path => ref $self,
        version => $self->version,
    );

    my $result = $self->_persistence->create_result({
        tool => $tool,
        test_name => $self->test_name,
        creating_process => $self->_process,
        inputs => $self->_raw_inputs,
        outputs => $self->_get_outputs,
    });
    $logger->info("Created result (", $result, ")");

    $self->_persistence->add_step_to_process(
        label => $self->_step_label,
        process => $self->_process,
        result => $result,
    );

    return;
}

sub _get_outputs {
    my $self = shift;

    my %result;
    for my $output_name ($self->outputs) {
        $result{$output_name} = $self->$output_name;
    }

    return \%result;
}


no Procera::Tool::Detail::AttributeSetter;
__PACKAGE__->meta->make_immutable;
