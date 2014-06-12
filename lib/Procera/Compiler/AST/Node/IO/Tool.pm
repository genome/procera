package Procera::Compiler::AST::Node::IO::Tool;

use Moose;
use warnings FATAL => 'all';

use Carp qw(confess);
use Memoize;
use Procera::WorkflowBuilder::Command;
use Procera::SourceFile qw(use_source_path);

extends 'Procera::Compiler::AST::Node::IO';

sub BUILD {
    my $self = shift;

    use_source_path($self->source_path);
    $self->_set_inputs;
    $self->_set_outputs;
    $self->_set_params;
    $self->_set_constants;
    return;
}

sub is_tool {
    return 1;
}

sub type {
    return 'Tool';
}

sub dag {
    my $self = shift;

    my $op = Procera::WorkflowBuilder::Command->new(
        name => $self->alias,
        command => $self->source_path,
        parallel_by => $self->parallel,
    );
    if ($self->lsf_resource) {
        $op->lsf_resource($self->lsf_resource);
    }
    return $op;
}
Memoize::memoize('dag');

sub lsf_resource {
    my $self = shift;

    my $tool_class = $self->source_path;
    if ($tool_class->can('lsf_resource')) {
        return $tool_class->lsf_resource();
    } else {
        return;
    }
}

sub _set_inputs {
    my $self = shift;

    my $tool_class = $self->source_path;
    for my $name ($tool_class->inputs) {
        $self->_add_input(name => $name);
    }
    return;
}

sub _set_outputs {
    my $self = shift;

    my $tool_class = $self->source_path;
    for my $name ($tool_class->outputs) {
        $self->_add_output(name => $name);
    }
    return;
}

sub _set_params {
    my $self = shift;

    my $tool_class = $self->source_path;
    for my $name ($tool_class->params) {
        $self->_add_param(name => $name);
    }
    return;
}

sub _set_constants {
    my $self = shift;

    my %constants;
    for my $coupler ($self->constant_couplers) {
        $constants{$coupler->name} = $coupler->value;
    }
    $self->constants(\%constants);
}


1;
