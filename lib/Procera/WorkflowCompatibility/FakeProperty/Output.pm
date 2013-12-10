package Procera::WorkflowCompatibility::FakeProperty::Output;
use Moose;
use warnings FATAL => 'all';

extends 'Procera::WorkflowCompatibility::FakeProperty';

sub is_output { 1; }

sub is_many {
    return;
}

__PACKAGE__->meta->make_immutable;
