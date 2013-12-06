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

    if ($params{is_many}) {
        return;  # For now we don't support this.
    }

    my @result;
    if ($params{is_input}) {
        push @result, @{$self->input_properties};
    } elsif ($params{is_output}) {
        push @result, @{$self->output_properties};
    } elsif ($params{is_param}) {
        push @result, @{$self->param_properties};
    } else {
        push @result, @{$self->input_properties};
        push @result, @{$self->output_properties};
        push @result, @{$self->param_properties};
    }

    if (my $property_name = $params{property_name}) {
        @result = grep {$_->property_name eq $property_name} @result;
    }
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
