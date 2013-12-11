package Procera::Compiler::AST::DataEndPoint;

use Moose;
use warnings FATAL => 'all';

has 'node' => (
    is => 'ro',
    isa => 'Procera::Compiler::AST::Node',
    required => 1,
);
has 'name' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

sub full_name {
    my $self = shift;

    return sprintf("%s.%s", $self->node->alias, $self->name);
}

1;
