package Procera::Curator;
use Moose;
use warnings FATAL => 'all';

use Carp qw(confess);
use File::Spec qw();
use Procera::Compiler::AST::NodeFactory;
use Memoize qw();

has 'source_path' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has '_inputs' => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    predicate => 'has_inputs',
);
has '_params' => (
    is => 'rw',
    isa => 'HashRef[Str]',
    predicate => 'has_params',
);
has '_outputs' => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    predicate => 'has_outputs',
);

sub ast_node {
    my $self = shift;
    my $node = Procera::Compiler::AST::NodeFactory::new_node(
        source_path => $self->source_path);
    return $node;
}
Memoize::memoize('ast_node');

sub actual_path {
    my $self = shift;

    my $path = $self->_path_to_gms;
    unless (defined($path)) {
        $path = $self->_path_to_tool;
        unless (defined($path)) {
            confess sprintf(
                "Couldn't determine actual source for source-path (%s)",
                $self->source_path);
        }
    }
    return $path;
}

sub _path_to_gms {
    my $self = shift;
    my $path = Procera::Compiler::AST::NodeFactory::resolve_path(
        $self->source_path);
    return $path;
}

sub _path_to_tool {
    my $self = shift;
    my $pm = File::Spec->join(split(/::/, $self->source_path)) . '.pm';
    my $path = $INC{$pm};
    return $path;
}

sub type {
    my $self = shift;
    if ($self->ast_node->is_tool) {
        return 'Tool';
    } else {
        return 'Process';
    }
}

sub inputs {
    my $self = shift;
    if (!$self->has_inputs) {
        $self->_inputs([sort keys %{$self->ast_node->inputs}]);
    }
    return $self->_inputs;
}

sub outputs {
    my $self = shift;
    if (!$self->has_outputs) {
        $self->_outputs([sort keys %{$self->ast_node->outputs}]);
    }
    return $self->_outputs;
}

sub params {
    my $self = shift;

    if (!$self->has_params) {
        $self->_params({});
        $self->_fill_params($self->ast_node, '');
    }
    return $self->_params;
}

sub _fill_params {
    my ($self, $node, $prefix) = @_;

    if ($node->is_tool) {
        for my $param_name ($node->source_path->_non_contextual_params) {
            my $full_param_name = $prefix ? "$prefix.$param_name" : $param_name;
            $self->_params->{$full_param_name} = $node->constants->{$param_name};
        }
    } else {
        for my $subnode (@{$node->nodes}) {
            my $subprefix = $prefix ? join('.', $prefix, $subnode->alias) : $subnode->alias;
            $self->_fill_params($subnode, $subprefix);
        }
    }
}

__PACKAGE__->meta->make_immutable;
