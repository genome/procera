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

sub output {
    my $self = shift;

    return $self->_create_data_end_point(name => 'output');
}

sub input {
    my $self = shift;

    $self->num_inputs($self->num_inputs + 1);
    return $self->_create_data_end_point(
        name => sprintf('input_%05d', $self->num_inputs),
    );
}

sub dag {
    my $self = shift;

    return Genome::WorkflowBuilder::Converge->create(
        name => "Converge",
    );
}
Memoize::memoize('dag');

1;
