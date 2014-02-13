package TestTool::MakeArrayOfFiles;
use Procera::Tool;
use warnings FATAL => 'all';

use File::Slurp qw(write_file);

has_input 'contents_1' => (
    isa => 'Str',
);
has_input 'contents_2' => (
    isa => 'Str',
);

has_output output_files => (
    isa => 'ArrayRef[Str]',
    array => 1,
);


sub execute_tool {
    my $self = shift;

    my $filename1 = 'file1.txt';
    my $filename2 = 'file2.txt';

    $self->output_files([$filename1, $filename2]);

    write_file($filename1, $self->contents_1);
    write_file($filename2, $self->contents_2);

    return;
}


__PACKAGE__->meta->make_immutable;

