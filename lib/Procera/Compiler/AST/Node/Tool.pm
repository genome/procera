package Procera::Compiler::AST::Node::Tool;

use Moose;
use warnings FATAL => 'all';

use Carp qw(confess);
use Memoize;
use Genome;

use Procera::Compiler::AST::Node;

extends 'Procera::Compiler::AST::Node';

sub BUILD {
    my $self = shift;

    $self->uuid($self->_new_uuid);

    _use_source_path($self->source_path);
    $self->_set_inputs;
    $self->_set_outputs;
    $self->_set_params;
    $self->_set_constants;
    return;
}

sub dag {
    my $self = shift;

    return Genome::WorkflowBuilder::Command->create(
        name => $self->alias,
        command => $self->source_path,
        parallel_by => $self->parallel,
    );
}
Memoize::memoize('dag');

sub dot_nodes {
    my $self = shift;

    return [sprintf('%s [label="%s"];', $self->uuid, $self->alias)];
}

sub dot_links {
    return [];
}

sub dot_cluster {
    return;
}

sub _use_source_path {
    my $source_path = shift;

    eval "use $source_path";
    if ($@) {
        confess sprintf("Couldn't use tool '%s': %s", $source_path, $@);
    }
    return;
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