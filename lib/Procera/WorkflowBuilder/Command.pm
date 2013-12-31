package Procera::WorkflowBuilder::Command;

use Moose;
use warnings FATAL => 'all';

with 'Procera::WorkflowBuilder::Detail::Operation';
with 'Procera::WorkflowBuilder::Detail::Element';

has command => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has lsf_queue => (
    is => 'rw',
    isa => 'Str',
);
has lsf_project => (
    is => 'rw',
    isa => 'Str',
);
has lsf_resource => (
    is => 'rw',
    isa => 'Str',
);

sub BUILD {
    my $self = shift;

    eval sprintf("require %s", $self->command);
    my $error = $@;
    if ($error) {
        Carp::confess(sprintf("Failed to load command class (%s)",
                $self->command));
    }
}


# ------------------------------------------------------------------------------
# Inherited Methods
# ------------------------------------------------------------------------------

sub from_xml_element {
    my ($class, $element) = @_;

    my $command_class = $class->_get_command_class_from_xml_element($element);

    return $class->new(
        name => $element->getAttribute('name'),
        command => $command_class,
        parallel_by => $element->getAttribute('parallelBy'),
    );
}

my %_EXPECTED_ATTRIBUTES = (
    lsf_project => 'lsfProject',
    lsf_queue => 'lsfQueue',
    lsf_resource => 'lsfResource',
);
sub input_properties {
    my $self = shift;
    return sort $self->command->inputs, $self->command->params;
}

sub operation_type_attributes {
    my $self = shift;
    my %attributes = (
        commandClass => $self->command,
    );
    for my $name (keys(%_EXPECTED_ATTRIBUTES)) {
        my $value;
        if (defined($self->$name)) {
            $value = $self->$name;
        } else {
            $value = $self->_get_attribue_from_command($name);
        }

        if (defined($value)) {
            $attributes{$_EXPECTED_ATTRIBUTES{$name}} = $value;
        }
    }
    return %attributes;
}

sub output_properties {
    my $self = shift;
    return sort map {$_->property_name} $self->command->__meta__->properties(
        is_output => 1);
}

sub validate {
    my $self = shift;

    if (defined($self->parallel_by)) {
        unless ($self->is_input_property($self->parallel_by)) {
            die sprintf("Failed to verify that requested "
                    . "parallel_by property '%s' was an input",
                    $self->parallel_by);
        }
    }
}

sub is_input_property {
    my ($self, $property_name) = @_;
    return $self->command->__meta__->properties(
            property_name => $property_name, is_input => 1)
        || $self->command->__meta__->properties(
            property_name => $property_name, is_param => 1);
}

sub is_output_property {
    my ($self, $property_name) = @_;
    return $self->command->__meta__->properties(property_name => $property_name,
        is_output => 1);
}

sub is_many_property {
    my ($self, $property_name) = @_;
    return $self->command->__meta__->properties(property_name => $property_name,
        is_many => 1);
}


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------

sub _get_attribue_from_command {
    my ($self, $property_name) = @_;

    return $self->command->$property_name;
}

sub _get_command_class_from_xml_element {
    my ($class, $element) = @_;

    my $nodes = $element->find('operationtype');
    my $operation_type_element = $nodes->pop;
    return $operation_type_element->getAttribute('commandClass');
}


__PACKAGE__->meta->make_immutable;
