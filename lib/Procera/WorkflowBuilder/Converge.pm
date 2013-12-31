package Procera::WorkflowBuilder::Converge;

use Moose;
use warnings FATAL => 'all';

with 'Procera::WorkflowBuilder::Detail::Operation';
with 'Procera::WorkflowBuilder::Detail::Element';

use Procera::Tool::Detail::Input;
use Procera::Tool::Detail::Output;
use Procera::Tool::Detail::Param;

has _input_properties => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub { [] },
);
has _output_properties => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub { [] },
);


sub input_properties {
    my $self = shift;
    return @{$self->_input_properties};
}

sub output_properties {
    my $self = shift;
    return @{$self->_output_properties};
}

sub validate {}

sub from_xml_element {
    my ($class, $element) = @_;

    my @input_properties = map {$_->textContent}
        $element->findnodes('.//inputproperty');
    my @output_properties = map {$_->textContent}
        $element->findnodes('.//outputproperty');
    return $class->new(
        name => $element->getAttribute('name'),
        _input_properties => \@input_properties,
        _output_properties => \@output_properties,
    );
}


sub operation_type_attributes { my %thing; return %thing; }

sub is_input_property {
    my ($self, $name) = @_;

    return Set::Scalar->new(@{$self->_input_properties})->contains($name);
}

sub is_output_property {
    my ($self, $name) = @_;

    return Set::Scalar->new(@{$self->_output_properties})->contains($name);
}

sub is_many_property {}


sub notify_input_link {
    my ($self, $link) = @_;

    unless ($self->is_input_property($link->destination_property)) {
        push @{$self->_input_properties}, $link->destination_property;
    }

    return;
}

sub notify_output_link {
    my ($self, $link) = @_;

    unless ($self->is_output_property($link->source_property)) {
        push @{$self->_output_properties}, $link->source_property;
    }

    return;
}

1;
