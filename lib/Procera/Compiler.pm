package Procera::Compiler;

use Moose;
use warnings FATAL => 'all';

use Carp qw(confess);
use Data::Dumper;

use Procera::Compiler::Parser;

use File::Slurp qw();
use File::Spec qw();
use File::Path qw();

use IO::File qw();
use XML::Tidy qw();
use Procera::InputFile;


with 'MooseX::Getopt';

has 'input-file' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    reader => 'input_file',
);
has 'output-directory' => (
    is => 'ro',
    isa => 'Str',
    reader => 'output_directory',
);

has workflow_file => (
    is => 'rw',
    isa => 'Str',
    traits => ['NoGetopt'],
);
has inputs_file => (
    is => 'rw',
    isa => 'Str',
    traits => ['NoGetopt'],
);

sub execute {
    my $self = shift;

    my $root_process = Procera::Compiler::Parser::new_process(
        $self->input_file, 'root');
    $root_process->set_step_labels();

    $self->make_output_directory;

    $self->save_inputs_file($root_process);

    $self->save_data('workflow.xml', $root_process->dag->get_xml);
    $self->format_xml('workflow.xml');

    $self->workflow_file($self->output_path('workflow.xml'));
    $self->inputs_file($self->output_path('inputs.tsv'));

    return 1;
}

sub save_inputs_file {
    my ($self, $process) = @_;

    my $input_file = Procera::InputFile->create_from_process_node($process);

    $input_file->write_to_filename($self->output_path('inputs.tsv'));
    return;
}

sub get_output_directory {
    my $self = shift;

    return $self->output_directory if $self->output_directory;
    return $self->default_output_directory;
}

sub default_output_directory {
    my $self = shift;

    my $path = $self->input_file;
    my $extension = $Procera::SourceFile::EXTENSION;
    $path =~ s/$extension$//;
    return $path . '/';
}

sub make_output_directory {
    my $self = shift;

    File::Path::remove_tree($self->get_output_directory);
    File::Path::make_path($self->get_output_directory);
    return;
}

sub save_data {
    my ($self, $filename, $data) = @_;

    File::Slurp::write_file($self->output_path($filename), $data);
    return;
}

sub output_path {
    my ($self, $filename) = @_;

    return File::Spec->join($self->get_output_directory, $filename);
}

sub format_xml {
    my ($self, $filename) = @_;

    my $tidy_obj = XML::Tidy->new(filename => $self->output_path($filename));
    $tidy_obj->tidy;
    $tidy_obj->write;

    return;
}


1;
