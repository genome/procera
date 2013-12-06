package Procera::WorkflowCompatibility::FakeProperty::Output;
use Moose;
use warnings FATAL => 'all';

extends 'Procera::WorkflowCompatibility::FakeProperty';

sub is_output { 1; }

__PACKAGE__->meta->make_immutable;
