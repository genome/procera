package WorkflowBuilder::Test::DummyCommandTwoInputs;

use Moose;
use warnings FATAL => 'all';

use Procera::Tool::Detail::Input;

extends ('WorkflowBuilder::Test::DummyCommand');

has 'input_two' => (
    is => 'rw',
    traits => ['Input'],
    required => 1,
);


__PACKAGE__->meta->make_immutable;
