package TestTool::ConcatArray;
use Procera::Tool;
use warnings FATAL => 'all';

has_input 'input_array' => (
    isa => 'ArrayRef[Str]',
    array => 1,
);

has_output 'combination' => (
    isa => 'Str',
    save => 0,
);


sub execute_tool {
    my $self = shift;

    $self->combination(join(':', @{$self->input_array}));

    return;
}


__PACKAGE__->meta->make_immutable;
