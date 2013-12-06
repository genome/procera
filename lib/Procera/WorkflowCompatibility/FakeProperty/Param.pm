package Procera::WorkflowCompatibility::FakeProperty::Param;
use Moose;
use warnings FATAL => 'all';

extends 'Procera::WorkflowCompatibility::FakeProperty';

sub is_param { 1; }

__PACKAGE__->meta->make_immutable;
