package Procera::WorkflowBuilder::Detail::Operation;

use Moose::Role;
use warnings FATAL => 'all';

use Procera::WorkflowBuilder::Detail::TypeMap;
use IO::File qw();
use IO::Scalar qw();
use Set::Scalar qw();
use XML::LibXML qw();
use Carp qw(confess);
use Data::Dumper qw();

use autodie qw(:io);

has name => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has log_dir => (
    is => 'rw',
    isa => 'Str',
);

has parallel_by => (
    is => 'rw',
    isa => 'Maybe[Str]',
);


# ------------------------------------------------------------------------------
# Abstract methods
# ------------------------------------------------------------------------------

requires 'from_xml_element';

requires 'input_properties';
requires 'output_properties';
requires 'operation_type_attributes';

requires 'is_input_property';
requires 'is_output_property';
requires 'is_many_property';


sub from_xml_element {
    my ($class, $element) = @_;

    # Prevent accidental recursion when subclasses don't override this method
    unless ($class eq 'Procera::WorkflowBuilder::Detail::Operation') {
        confess sprintf(
                "from_xml_element not implemented in subclass %s", $class);
    }

    my $subclass = $class->_get_subclass_from_element($element);
    return $subclass->from_xml_element($element);
}


# ------------------------------------------------------------------------------
# Public methods
# ------------------------------------------------------------------------------

sub execute {
    require Workflow::Simple;

    my $self = shift;
    my $result = Workflow::Simple::run_workflow_lsf($self->get_xml, @_);
    unless (defined($result)) {
        die sprintf(
            "Workflow failed with these errors: %s",
            Data::Dumper::Dumper(map {$_->error} @Workflow::Simple::ERROR)
        );
    }
    return $result;
}

sub from_xml {
    my ($class, $xml) = @_;
    my $fh = new IO::Scalar \$xml;

    return $class->from_xml_file($fh);
}

sub from_xml_file {
    my ($class, $fh) = @_;
    my $doc = XML::LibXML->load_xml(IO => $fh);
    return $class->from_xml_element($doc->documentElement);
}

sub from_xml_filename {
    my ($class, $filename) = @_;

    my $fh = IO::File->new($filename, 'r');
    return $class->from_xml_file($fh);
}

sub operation_type {
    my $self = shift;

    return Procera::WorkflowBuilder::Detail::TypeMap::type_from_class(
        ref $self);
}


# ------------------------------------------------------------------------------
# Inherited methods
# ------------------------------------------------------------------------------

sub notify_input_link {}

sub notify_output_link {}

sub get_xml {
    my $self = shift;

    $self->validate;

    my $doc = XML::LibXML::Document->new();
    $doc->setDocumentElement($self->get_xml_element);

    return $doc->toString(1);
}

sub get_xml_element {
    my $self = shift;

    my $element = XML::LibXML::Element->new('operation');
    $element->setAttribute('name', $self->name);

    if (defined($self->parallel_by)) {
        $element->setAttribute('parallelBy', $self->parallel_by);
    }

    $element->addChild($self->_get_operation_type_xml_element);

    return $element;
}

my $_INVALID_NAMES = new Set::Scalar('input connector', 'output connector');
before validate => sub {
    my $self = shift;

    if ($_INVALID_NAMES->contains($self->name)) {
        die sprintf("Operation name '%s' is not allowed",
            $self->name);
    }

    return;
};


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------

sub _get_operation_type_xml_element {
    my $self = shift;

    my $element = XML::LibXML::Element->new('operationtype');

    $element->setAttribute('typeClass', $self->operation_type);

    map {$self->_add_property_xml_element($element, 'inputproperty', $_)}
        $self->input_properties;
    map {$self->_add_property_xml_element($element, 'outputproperty', $_)}
        $self->output_properties;

    my %attributes = $self->operation_type_attributes;
    for my $attr_name (keys(%attributes)) {
        $element->setAttribute($attr_name, $attributes{$attr_name});
    }

    return $element;
}

sub _add_property_xml_element {
    my ($self, $element, $xml_tag, $text) = @_;

    my $inner_element = XML::LibXML::Element->new($xml_tag);
    $inner_element->appendText($text);
    $element->addChild($inner_element);

    return;
}

sub _get_subclass_from_element {
    my ($class, $element) = @_;
    my $nodes = $element->find('operationtype');
    my $operation_type_element = $nodes->pop;
    return Procera::WorkflowBuilder::Detail::TypeMap::class_from_type(
        $operation_type_element->getAttribute('typeClass'));
}

1;
