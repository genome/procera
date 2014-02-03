package Procera::Tool::Detail::AttributeSetter;
use Moose qw();
use warnings FATAL => 'all';

use Moose::Exporter qw();
use Carp qw(confess);
use Set::Scalar;

use Procera::Tool::Detail::Input;
use Procera::Tool::Detail::Output;
use Procera::Tool::Detail::Param;


sub has_input {
    my $meta = shift;
    my $name = shift;

    validate($name);
    Moose::has($meta, $name, is => 'rw', traits => ['Input'],
        required => 1, @_);
}

sub has_output {
    my $meta = shift;
    my $name = shift;

    validate($name);
    Moose::has($meta, $name, is => 'rw', traits => ['Output'], @_);
}

sub has_param {
    my $meta = shift;
    my $name = shift;

    validate($name);
    Moose::has($meta, $name, is => 'rw', traits => ['Param'],
        required => 1, @_);
}

sub has_inputs {
    my $meta = shift;
    my $inputs = shift;
    for my $input_name (keys %$inputs) {
        has_input($meta, $input_name, %{$inputs->{$input_name}});
    }
}

sub has_outputs {
    my $meta = shift;
    my $outputs = shift;
    for my $output_name (keys %$outputs) {
        has_output($meta, $output_name, %{$outputs->{$output_name}});
    }
}

sub has_params {
    my $meta = shift;
    my $params = shift;
    for my $param_name (keys %$params) {
        has_param($meta, $param_name, %{$params->{$param_name}});
    }
}

Moose::Exporter->setup_import_methods(
    with_meta => [qw(has_input has_inputs
                     has_output has_outputs
                     has_param has_params)],
);

my $RESERVED_NAMES = Set::Scalar->new(qw(
    execute
    shortcut
    execute_tool
    inputs
    outputs
    params
    _cache_raw_inputs
    _cleanup
    _create_fileset_for_outputs
    _create_result
    _get_output_path_to_name_map
    _get_outputs
    _inputs_as_hashref
    _inputs_with_locations
    _is_absolute
    _make_path
    _md5sum
    _non_contextual_input_names
    _non_contextual_params
    _output_file_hash
    _output_file_hashes
    _persistence
    _property_names
    _reset_inputs_with_locations
    _save
    _saved_file_names
    _set_output_uris
    _set_outputs_from_result
    _setup
    _setup_workspace
    _storage
    _symlink_inputs
    _symlink_into_workspace
    _translate_inputs
    _verify_outputs_in_workspace
));

sub validate {
    my $name = shift;
    if ($RESERVED_NAMES->contains($name)) {
        confess "The name ($name) is reserved, choose another name";
    }
}



1;
