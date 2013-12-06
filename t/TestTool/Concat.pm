package TestTool::Concat;
use Procera::Tool;
use warnings FATAL => 'all';

has_input 'prefix';
has_input 'suffix';

has_output 'combination' => (save => 0);


sub execute_tool {
    my $self = shift;

    $self->combination(join(':', $self->prefix, $self->suffix));

    return;
}


__PACKAGE__->meta->make_immutable;
