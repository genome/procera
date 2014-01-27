package Procera::Persistence::Amber;

use Moose;
use warnings FATAL => 'all';

with 'Procera::Persistence::Detail::Role';

use Data::Dumper qw();
use JSON qw();
use LWP::UserAgent qw();
use Params::Validate qw();
use URI::URL qw();


my $_json_codec = JSON->new;
my $_user_agent = LWP::UserAgent->new;


sub create_process {
    my ($self, $content) = @_;
    my $post_response = $self->_post('/v1/processes/', $content);

    return $self->_get_created_url($post_response);
}

sub get_process {
    my ($self, $path) = @_;

    return $self->_get_or_die($path);
}

sub create_result {
    my ($self, $content) = @_;
    my $post_response = $self->_post('/v1/results/', $content);

    return $self->_get_created_url($post_response);
}

sub get_result {
    my $self = shift;

    my $checkpoint_response = $self->_checkpoint(@_);
    if ($checkpoint_response->code == 404) {
        return;
    } else {
        my $checkpoint_data = $self->_decode_response($checkpoint_response);
        return $self->_get_or_die($checkpoint_data->{objects}->[0]);
    }
}

sub _checkpoint {
    my $self = shift;
    my %params = Params::Validate::validate(@_, {
        inputs => { type => Params::Validate::HASHREF, required => 1, },
        tool_name => { type => Params::Validate::SCALAR, required => 1, },
        test_name => { type => Params::Validate::SCALAR, required => 1, },
    });

    return $self->_post('/v1/checkpoint/', \%params);
}

sub create_fileset {
    my ($self, $content) = @_;
    my $post_response = $self->_post('/v1/filesets/', $content);

    return $self->_get_created_resource($post_response);
}

sub add_step_to_process {
    my $self = shift;
    my %params = Params::Validate::validate(@_, {
        process => { type => Params::Validate::SCALAR, required => 1, },
        result => { type => Params::Validate::SCALAR, required => 1, },
        label => { type => Params::Validate::SCALAR, required => 1, },
    });

    my $post_response = $self->_post('/v1/process-steps/', {
        label => $params{label},
        process => $params{process},
        result => $params{result},
    });

    return $self->_get_created_url($post_response);
}

sub get_file {
    my ($self, $path) = @_;

    return $self->_get_or_die($path);
}

sub get_allocation_id_for_fileset {
    my ($self, $fileset_uri) = @_;

    my $fileset = $self->_get_or_die($fileset_uri);
    if (@{$fileset->{allocations}}) {
        return $fileset->{allocations}->[0];
    } else {
        Carp::confess(sprintf("No allocations associated with fileset '%s'",
                $fileset->{resource_uri}));
    }
}

sub get_allocation_id_for_file {
    my ($self, $file_uri) = @_;

    my $file = $self->_get_or_die($file_uri);
    return $self->get_allocation_id_for_fileset($file->{fileset});
}

sub _get_or_die {
    my ($self, $path) = @_;
    return $self->_decode_response($self->_get($path));
}

sub _get {
    my ($self, $path) = @_;

    return $_user_agent->get($self->_full_url($path),
        'Accepts' => 'application/json',
        'Content-Type' => 'application/json');
}

sub _full_url {
    my ($self, $path) = @_;

    return URI::URL->new($path, $self->_base_url)->abs;
}

sub _base_url {
    my $self = shift;

    return $ENV{AMBER_URL}
        or Carp::confess("Environment variable AMBER_URL not set");
}


sub _post {
    my ($self, $path, $data) = @_;
    my $response = $_user_agent->post($self->_full_url($path),
        'Accepts' => 'application/json',
        'Content-Type' => 'application/json',
        Content => $_json_codec->encode($data));

    return $response;
}

sub _get_created_resource {
    my ($self, $post_response) = @_;
    if ($post_response->is_success) {
        return $self->_decode_response($self->_get(
                $post_response->header('Location')));
    } else {
        Carp::confess(sprintf("Failed to create resource: %s",
                Data::Dumper::Dumper($post_response)));
    }
}

sub _get_created_url {
    my ($self, $post_response) = @_;

    if ($post_response->is_success) {
        my $uri = URI::URL->new($post_response->header('Location'));
        return $uri->path;
    } else {
        Carp::confess(sprintf("Failed to create resource: %s",
                Data::Dumper::Dumper($post_response)));
    }
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


__PACKAGE__->meta->make_immutable;
