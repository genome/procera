package Procera::Persistence::Detail::Restful;

use Moose::Role;
use warnings FATAL => 'all';

use Data::Dumper qw();
use JSON qw();
use LWP::UserAgent qw();
use URI::URL qw();

requires 'base_url';

my $_json_codec = JSON->new;
my $_user_agent = LWP::UserAgent->new;

sub _get_or_die {
    my ($self, $path) = @_;
    return $self->_decode_response($self->_get($path));
}

sub _decode_response {
    my ($self, $response) = @_;

    if ($response->is_success) {
        return $_json_codec->decode(
            $response->decoded_content(raise_error => 1));
    } else {
        Carp::confess(sprintf("Can't extract content from failed response: %s",
                Data::Dumper::Dumper($response)));
    }
}

sub _get {
    my ($self, $path) = @_;

    return $_user_agent->get($self->_full_url($path),
        'Accepts' => 'application/json',
        'Content-Type' => 'application/json');
}

sub _full_url {
    my ($self, $path) = @_;

    return URI::URL->new($path, $self->base_url)->abs;
}

sub _post {
    my ($self, $path, $data) = @_;
    my $response = $_user_agent->post($self->_full_url($path),
        'Accepts' => 'application/json',
        'Content-Type' => 'application/json',
        Content => $_json_codec->encode($data));

    return $response;
}

sub _put {
    my ($self, $path, $data) = @_;
    my $response = $_user_agent->put($self->_full_url($path),
        'Accepts' => 'application/json',
        'Content-Type' => 'application/json',
        Content => $_json_codec->encode($data));

    return $response;
}

1;
