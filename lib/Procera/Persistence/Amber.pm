package Procera::Persistence::Amber;

use Moose;
use warnings FATAL => 'all';

with 'Procera::Persistence::Detail::Role';
with 'Procera::Persistence::Detail::Restful';

use Data::Dumper qw();
use Params::Validate qw(validate_pos);
use URI::URL qw();
use Procera::Persistence::Detail::AmberIterator;


sub base_url {
    my $self = shift;

    return $ENV{AMBER_URL}
        or Carp::confess("Environment variable AMBER_URL not set");
}

sub get_process_steps_iterator {
    my ($self, $process_id) = validate_pos(@_, 1, 1);

    my $uri = "/v1/process-steps/?process=$process_id";
    return $self->get_objects_iterator($uri);
}

sub get_objects_iterator {
    my ($self, $uri) = validate_pos(@_, 1, 1);
    return Procera::Persistence::Detail::AmberIterator->new(uri => $uri);
}

sub create_process {
    my ($self, $content) = @_;
    my $post_response = $self->_post('/v1/processes/', $content);

    return $self->_get_created_url($post_response);
}

sub register_tool {
    my $self = shift;
    my %params = Params::Validate::validate(@_, {
        source_path => { type => Params::Validate::SCALAR, required => 1, },
        version => { type => Params::Validate::SCALAR, required => 1, },
    });

    my $response = $self->_post('/v1/register-tool/', \%params);
    my $tool_data = $self->_decode_response($response);
    return $self->_get_or_die($tool_data->{objects}->[0]);
}

sub get_process {
    my ($self, $path) = @_;

    return $self->_get_or_die($path);
}

sub get_process_steps {
    my ($self, $process_id) = @_;

    my $path = "/v1/process-steps/?process=$process_id";
    return $self->_get_or_die($path)->{objects};
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
        source_path => { type => Params::Validate::SCALAR, required => 1, },
        version => { type => Params::Validate::SCALAR, required => 1, },
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
    return $fileset->{allocation_id};
}

sub get_allocation_id_for_file {
    my ($self, $file_uri) = @_;

    my $file = $self->_get_or_die($file_uri);
    return $self->get_allocation_id_for_fileset($file->{fileset});
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


__PACKAGE__->meta->make_immutable;
