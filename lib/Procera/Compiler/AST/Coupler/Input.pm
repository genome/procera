package Procera::Compiler::AST::Coupler::Input;

use Moose;
use warnings FATAL => 'all';

extends 'Procera::Compiler::AST::Coupler';

has input_name => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

sub is_internal { return 0; }
sub is_input { return 1; }
sub is_output { return 0; }
sub is_constant { return 0; }


1;
