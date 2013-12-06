package Procera::WorkflowCompatibility::FakeProperty;
use Moose;
use warnings FATAL => 'all';


has 'property_name' => (
    is => 'ro',
    required => 1,
);
has 'is_many' => (
    is => 'ro',
    isa => 'Bool',
);


sub is_input {}
sub is_output {}
sub is_param {}


sub id_by { [] }

sub default_value {}
sub is_optional {}
sub via {}


__PACKAGE__->meta->make_immutable;
