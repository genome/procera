package WorkflowBuilder::Test::DummyCommand;

use Moose;
use warnings FATAL => 'all';

with 'Procera::WorkflowCompatibility::Role';

use Procera::Tool::Detail::Input;
use Procera::Tool::Detail::Output;


has input => (
    is => 'rw',
    traits => ['Input'],
    required => 1,
);

has single_output => (
    is => 'rw',
    traits => ['Output'],
);

has many_output => (
    is => 'rw',
    traits => ['Output'],
    array => 1,
);


sub lsf_resource {
    return "-M 25000000 -R 'select[mem>25000] rusage[mem=25000]'";
}

sub lsf_queue {
    return $ENV{TEST_WORKFLOW_BUILDER_QUEUE};
}


sub inputs {
    my $class = shift;

    return map {$_->name} grep {$_->does('Input')}
        $class->meta->get_all_attributes;
}

sub outputs {
    my $class = shift;

    return map {$_->name} grep {$_->does('Output')}
        $class->meta->get_all_attributes;
}

sub params {
    my $class = shift;

    return map {$_->name} grep {$_->does('Param')}
        $class->meta->get_all_attributes;
}


__PACKAGE__->meta->make_immutable;
