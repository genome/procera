package Procera::WorkflowCompatibility::FakePropertyHolder;
use Moose;
use warnings FATAL => 'all';

use Params::Validate qw();

has 'input_properties' => (
    is => 'ro',
    isa => 'ArrayRef[Procera::WorkflowCompatibility::FakeProperty::Input]',
    default => sub {[]},
);

has 'output_properties' => (
    is => 'ro',
    isa => 'ArrayRef[Procera::WorkflowCompatibility::FakeProperty::Output]',
    default => sub {[]},
);

has 'param_properties' => (
    is => 'ro',
    isa => 'ArrayRef[Procera::WorkflowCompatibility::FakeProperty::Param]',
    default => sub {[]},
);

sub _input_properties_set {
    my $self = shift;

    return _property_name_set(@{$self->input_properties});
}

sub _output_properties_set {
    my $self = shift;

    return _property_name_set(@{$self->output_properties});
}

sub _param_properties_set {
    my $self = shift;

    return _property_name_set(@{$self->param_properties});
}

sub _all_properties_set {
    my $self = shift;

    return _property_name_set(
        @{$self->input_properties},
        @{$self->output_properties},
        @{$self->param_properties},
    );
}

sub _is_array_properties_set {
    my $self = shift;

    return _property_name_set(
        grep {$_->is_array} @{$self->input_properties},
        grep {$_->is_array} @{$self->output_properties},
        grep {$_->is_array} @{$self->param_properties},
    );
}

sub _property_name_set {
    return Set::Scalar->new(map {$_->property_name} @_);
}

sub _lookup_property {
    my ($self, $property_name) = @_;

    unless (exists($self->_property_hash->{$property_name})) {
        confess "Attempt to lookup unknown property named ($property_name)";
    }
    return $self->_property_hash->{$property_name};
}

sub _property_hash {
    my $self = shift;

    my %result;
    for my $property (
            @{$self->input_properties},
            @{$self->output_properties},
            @{$self->param_properties}) {
        $result{$property->property_name} = $property;
    }
    return \%result;
}

sub properties {
    my $self = shift;

    my %params = Params::Validate::validate(@_, {
        is_input => {
            type => Params::Validate::BOOLEAN,
            optional => 1,
        },
        is_many => {
            type => Params::Validate::BOOLEAN,
            optional => 1,
        },
        is_optional => {
            type => Params::Validate::BOOLEAN,
            optional => 1,
        },
        is_output => {
            type => Params::Validate::BOOLEAN,
            optional => 1,
        },
        is_param => {
            type => Params::Validate::BOOLEAN,
            optional => 1,
        },
        parallel_by => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
        property_name => {
            type => Params::Validate::SCALAR,
            optional => 1,
        },
    });

    delete $params{is_optional};  # Ignored.

    if (exists $params{parallel_by}) {
        confess "Moose-WorkflowCompatibility doesn't support parallel_by";
    }

    my $result;
    if ($params{is_input}) {
        $result = $self->_input_properties_set;
    } elsif ($params{is_output}) {
        $result = $self->_output_properties_set;
    } elsif ($params{is_param}) {
        $result = $self->_param_properties_set;
    } else {
        $result = $self->_all_properties_set;
    }

    if (my $property_name = $params{property_name}) {
        $result = $result->intersection(Set::Scalar->new($property_name));
    }

    if ($params{is_many}) {
        $result = $result->intersection($self->_is_array_properties_set);
    }


    my @result = map {$self->_lookup_property($_)} $result->members;
    if (wantarray) {
        return @result;
    } else {
        if (scalar(@result) == 1) {
            return $result[0];
        } elsif (scalar(@result) == 0) {
            return;
        } else {
            confess "Got multiple elements when requested scalar context";
        }
    }
}

sub all_property_metas {
    my $self = shift;
    return $self->properties;
}

sub property_meta_for_name {
    my ($self, $name) = @_;
    return $self->properties(property_name => $name);
}

sub property {
    my ($self, $name) = @_;
    return $self->property_meta_for_name($name);
}


__PACKAGE__->meta->make_immutable;
