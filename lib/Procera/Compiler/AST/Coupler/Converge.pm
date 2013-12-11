package Procera::Compiler::AST::Coupler::Converge;

use Moose;
use warnings FATAL => 'all';

extends 'Procera::Compiler::AST::Coupler';

has sources => (
    is => 'ro',
    isa => 'ArrayRef[Str | ArrayRef[Str]]',
    required => 1,
);

sub is_internal { return 0; }
sub is_input { return 0; }
sub is_output { return 0; }
sub is_constant { return 0; }
sub is_converge { return 1; }


1;

