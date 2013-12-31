package Procera::WorkflowBuilder::Detail::TypeMap;

use strict;
use warnings FATAL => 'all';

my %_CLASS_TO_TYPE_MAPPING = (
    'Procera::WorkflowBuilder::DAG' => 'Workflow::OperationType::Model',
    'Procera::WorkflowBuilder::Command' => 'Workflow::OperationType::Command',
    'Procera::WorkflowBuilder::Converge' => 'Workflow::OperationType::Converge',
);

my %_TYPE_TO_CLASS_MAPPING;
for my $class (keys(%_CLASS_TO_TYPE_MAPPING)) {
    $_TYPE_TO_CLASS_MAPPING{$_CLASS_TO_TYPE_MAPPING{$class}} = $class;
}

sub type_from_class {
    my $class = shift;

    return $_CLASS_TO_TYPE_MAPPING{$class};
}

sub class_from_type {
    my $type = shift;

    return $_TYPE_TO_CLASS_MAPPING{$type};
}

1;
