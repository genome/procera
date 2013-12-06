package Procera::Compiler::AST::Link;

use Moose;
use warnings FATAL => 'all';

has source => (
    is => 'ro',
    isa => 'Procera::Compiler::AST::DataEndPoint',
);
has destination => (
    is => 'ro',
    isa => 'Procera::Compiler::AST::DataEndPoint',
);

1;
