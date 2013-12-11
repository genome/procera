package Procera::Compiler::AST::Node;

use Moose;
use warnings FATAL => 'all';

use Carp qw(confess);

sub dag {
    confess 'Abstract method!';
}

sub _create_data_end_point {
    my $self  = shift;

    return Procera::Compiler::AST::DataEndPoint->new(node => $self, @_);
}


1;
