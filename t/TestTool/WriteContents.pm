package TestTool::WriteContents;
use Procera::Tool;
use warnings FATAL => 'all';

use File::Slurp qw(write_file);

has_input contents => (
    isa => 'Str',
);

has_output filename => (
    isa => 'Str',
);


sub execute_tool {
    my $self = shift;

    my $filename = 'file.txt';

    $self->filename($filename);

    write_file($filename, $self->contents);

    return;
}


__PACKAGE__->meta->make_immutable;
