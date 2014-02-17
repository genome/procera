package Procera::Persistence::Detail::AmberIterator;

use Moose;
use warnings FATAL => 'all';

with 'Procera::Persistence::Detail::Restful';

has 'uri' => (
    is => 'ro',
    isa => 'Str',
);
has '_objects' => (
    is => 'rw',
    isa => 'ArrayRef',
    required => 0,
    builder => '_build_objects',
);
has '_next_uri' => (
    is => 'rw',
    isa => 'Maybe[Str]',
    required => 0,
);

sub _build_objects {
    return [];
}

sub BUILD {
    my $self = shift;
    $self->_next_uri($self->uri);
}

sub next {
    my $self = shift;
    if (scalar(@{$self->_objects})) {
        return shift(@{$self->_objects});
    } elsif (defined($self->_next_uri)) {
        my $response = $self->_get_or_die($self->_next_uri);
        $self->_next_uri($response->{'meta'}->{'next'});
        $self->_objects($response->{'objects'});
        return $self->next();
    } else {
        return;
    }
}

sub base_url {
    my $self = shift;

    return $ENV{AMBER_URL}
        or Carp::confess("Environment variable AMBER_URL not set");
}


__PACKAGE__->meta->make_immutable;
