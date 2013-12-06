package Procera::Compiler::AST::Coupler;

use Moose;
use warnings FATAL => 'all';

use Carp qw(confess);

has name => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

sub is_internal { confess 'Abstract method'; }
sub is_input { confess 'Abstract method'; }
sub is_output { confess 'Abstract method'; }
sub is_constant { confess 'Abstract method'; }

1;
