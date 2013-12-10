package TestTool::MakeArray;
use Procera::Tool;
use warnings FATAL => 'all';

has_input 'a' => (
    isa => 'Str',
);
has_input 'b' => (
    isa => 'Str',
);

has_output 'output_array' => (
    isa => 'ArrayRef[Str]',
    array => 1,
    save => 0,
);


sub execute_tool {
    my $self = shift;

    $self->output_array([$self->a, $self->b]);

    return;
}


__PACKAGE__->meta->make_immutable;
