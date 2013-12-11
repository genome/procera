package Procera::Compiler::AST::Node::IO;

use Moose;
use warnings FATAL => 'all';

use Carp qw(confess);
use Memoize qw();

use Procera::Compiler::AST::DataEndPoint;
use Procera::Compiler::AST::Node;

extends "Procera::Compiler::AST::Node";

has source_path => (
    is => 'rw',
    isa => 'Str',
);
has parallel => (
    is => 'rw',
    isa => 'Str',
);
has couplers => (
    is => 'rw',
    isa => 'ArrayRef[Procera::Compiler::AST::Coupler]',
    default => sub {[]},
);

has alias => (
    is => 'rw',
    isa => 'Str',
);
has inputs => (
    is => 'rw',
    isa => 'HashRef[Procera::Compiler::AST::DataEndPoint]',
    default => sub {{}},
);
has outputs => (
    is => 'rw',
    isa => 'HashRef[Procera::Compiler::AST::DataEndPoint]',
    default => sub {{}},
);
has params => (
    is => 'rw',
    isa => 'HashRef[Procera::Compiler::AST::DataEndPoint]',
    default => sub {{}},
);
has constants => (
    is => 'rw',
    isa => 'HashRef[Value]',
    default => sub {{}},
);

sub constant_couplers {
    my $self = shift;

    return grep {$_->is_constant} @{$self->couplers};
}

sub internal_couplers {
    my $self = shift;

    return grep {$_->is_internal} @{$self->couplers};
}

sub input_couplers {
    my $self = shift;

    return grep {$_->is_input && !$_->is_constant} @{$self->couplers};
}

sub output_couplers {
    my $self = shift;

    return grep {$_->is_output} @{$self->couplers};
}

sub converge_couplers {
    my $self = shift;

    return grep {$_->is_converge} @{$self->couplers};
}



sub source_path_components {
    my $self = shift;

    my @parts = split /::/, $self->source_path;
    my @reversed_parts = reverse @parts;
    return \@reversed_parts;
}

sub _add_input {
    my $self = shift;

    my $input = $self->_create_data_end_point(@_);
    $self->inputs->{$input->name} = $input;
    return $input;
}

sub _add_output {
    my $self = shift;

    my $output = $self->_create_data_end_point(@_);
    if (exists $self->outputs->{$output->name}) {
        confess sprintf("Tried to create output named (%s) that already exists on node %s (%s)",
            $output->name, $self->source_path, $self->alias);
    } else {
        $self->outputs->{$output->name} = $output;
    }
    return $output;
}

sub _add_param {
    my $self = shift;

    my $param = $self->_create_data_end_point(@_);
    $self->params->{$param->name} = $param;
    return $param;
}


1;
