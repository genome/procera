package Procera::Persistence::Memory;

use MooseX::Singleton;
use warnings FATAL => 'all';

use Params::Validate qw(validate_pos);

with 'Procera::Persistence::Detail::Role';


has '_allocations' => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
);

has '_files' => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
);

has '_counter' => (
    is => 'rw',
    isa => 'Int',
    default => 1,
);

sub create_process {
    my ($self, $content) = validate_pos(@_, 1, 1);

    return $self->_get_label('processes');
}

sub create_result {
    my $self = shift;

    return $self->_get_label('results');
}

sub get_result {
    return undef;
}

sub create_fileset {
    my ($self, $content) = validate_pos(@_, 1, 1);

    my $fileset_label = $self->_get_label('filesets');
    $self->_allocations->{$fileset_label} = $content->{allocations}->[0];

    my @files;
    for my $file_data (@{$content->{files}}) {
        my %full_file_data = %$file_data;
        $full_file_data{fileset} = $fileset_label;

        push @files, \%full_file_data;
        my $file_label = $self->_get_label('files');
        $full_file_data{resource_uri} = $file_label;

        $self->_files->{$file_label} = \%full_file_data;
    }

    return {files => \@files};
}

sub add_step_to_process {
    return '/v1/process-steps/0/';
}

sub get_file {
    my ($self, $url) = validate_pos(@_, 1, 1);

    return $self->_files->{$url};
}

sub get_allocation_id_for_fileset {
    my ($self, $url) = validate_pos(@_, 1, 1);

    return $self->_allocations->{$url};
}

sub _get_label {
    my ($self, $base_label) = validate_pos(@_, 1, 1);

    my $label = sprintf("/v1/%s/%d", $base_label, $self->_counter);
    $self->_counter($self->_counter + 1);

    return $label;
}


__PACKAGE__->meta->make_immutable;
