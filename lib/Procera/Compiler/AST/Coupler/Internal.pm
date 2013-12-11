package Procera::Compiler::AST::Coupler::Internal;

use Moose;
use warnings FATAL => 'all';

extends 'Procera::Compiler::AST::Coupler';

has source_node_alias => (
    is => 'ro',
    isa => 'Str',
);
has source_name => (
    is => 'ro',
    isa => 'Str',
);

sub is_internal { return 1; }
sub is_input { return 0; }
sub is_output { return 0; }
sub is_constant { return 0; }
sub is_converge { return 0; }

1;
