package Procera::Compiler::AST::Node::Converge;

use Moose;
use warnings FATAL => 'all';
use Memoize qw();

use Carp qw(confess);

extends "Procera::Compiler::AST::Node";

has num_inputs => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);
has target_name => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

sub output {
    my $self = shift;

    return $self->_create_data_end_point(name => 'output');
}

sub next_input {
    my $self = shift;

    $self->num_inputs($self->num_inputs + 1);
    return $self->_create_data_end_point(
        name => sprintf('input_%05d', $self->num_inputs),
    );
}

sub dag {
    my $self = shift;

    return Genome::WorkflowBuilder::Converge->create(
        name => sprintf("Converge to %s", $self->target_name),
    );
}
Memoize::memoize('dag');

1;
