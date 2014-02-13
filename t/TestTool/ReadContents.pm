package TestTool::ReadContents;
use Procera::Tool;
use warnings FATAL => 'all';

use File::Slurp qw(read_file);

has_input filename => (
    isa => 'Str',
);

has_output contents => (
    isa => 'Str',
    save => 0,
);



sub execute_tool {
    my $self = shift;

    my $contents = read_file($self->filename);
    $self->contents($contents);

    return;
}


__PACKAGE__->meta->make_immutable;
