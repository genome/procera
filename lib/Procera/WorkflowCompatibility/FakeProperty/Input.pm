package Procera::WorkflowCompatibility::FakeProperty::Input;
use Moose;
use warnings FATAL => 'all';

extends 'Procera::WorkflowCompatibility::FakeProperty';

sub is_input { 1; }

__PACKAGE__->meta->make_immutable;
