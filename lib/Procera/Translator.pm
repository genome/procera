package Procera::Translator;

use Moose;
use warnings FATAL => 'all';


has persistence => (
    is => 'ro',
    required => 1,
);

has storage => (
    is => 'ro',
    required => 1,
);

sub resolve_scalar_or_url {
    my ($self, $scalar_or_url) = @_;

    return unless defined($scalar_or_url);

    if ($scalar_or_url =~ m/^\/v\d+\/.+/) {
        my @url_parts = split /\//, $scalar_or_url;

        if ($url_parts[2] eq 'files') {
            my $file_data = $self->persistence->get_file($scalar_or_url);
            my $allocation = $self->persistence->get_allocation_id_for_fileset(
                $file_data->{fileset});
            return $self->storage->get_copy_path($allocation,
                $file_data->{path});

        } elsif ($url_parts[2] eq 'processes') {
            return $self->persistence->get_process($scalar_or_url);

        } else {
            Carp::confess(sprintf("Unknown uri type: '%s'", $scalar_or_url));
        }
    } else {
        return $scalar_or_url;
    }
}


__PACKAGE__->meta->make_immutable;
