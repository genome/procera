package TestTool::ConcatArrayOfFiles;
use Procera::Tool;
use warnings FATAL => 'all';

use File::Slurp qw(read_file);

has_input input_files => (
    isa => 'ArrayRef[Str]',
    array => 1,
);

has_output combination => (
    isa => 'Str',
    save => 0,
);


sub execute_tool {
    my $self = shift;

    my @all_contents;
    for my $filename (@{$self->input_files}) {
        my $contents = read_file($filename);
        push @all_contents, $contents;
    }
    $self->combination(join('|', @all_contents));

    return;
}


__PACKAGE__->meta->make_immutable;
