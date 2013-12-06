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

1;
