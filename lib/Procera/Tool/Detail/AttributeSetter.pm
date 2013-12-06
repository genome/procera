package Procera::Tool::Detail::AttributeSetter;
use Moose qw();
use warnings FATAL => 'all';

use Moose::Exporter qw();


use Procera::Tool::Detail::Input;
use Procera::Tool::Detail::Output;
use Procera::Tool::Detail::Param;


sub has_input {
    my $meta = shift;
    my $name = shift;

    Moose::has($meta, $name, is => 'rw', traits => ['Input'],
        required => 1, @_);
}

sub has_output {
    my $meta = shift;
    my $name = shift;

    Moose::has($meta, $name, is => 'rw', traits => ['Output'], @_);
}

sub has_param {
    my $meta = shift;
    my $name = shift;

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


1;
