package Procera::WorkflowCompatibility::Role;
use Moose::Role;
use warnings FATAL => 'all';

use Procera::WorkflowCompatibility::FakeProperty::Input;
use Procera::WorkflowCompatibility::FakeProperty::Output;
use Procera::WorkflowCompatibility::FakeProperty::Param;
use Procera::WorkflowCompatibility::FakePropertyHolder;


sub __meta__ {
    my $class = shift;

    return Procera::WorkflowCompatibility::FakePropertyHolder->new(
        input_properties => $class->_input_properties,
        output_properties => $class->_output_properties,
        param_properties => $class->_param_properties
    );
}


sub create {
    my $class = shift;

    return $class->new(@_);
}

sub lsf_project {}
sub lsf_queue {}
sub lsf_resource {}


sub _input_properties {
    my $class = shift;
    my @result;
    for my $attr_name ($class->inputs) {
        push @result, Procera::WorkflowCompatibility::FakeProperty::Input->new(
            is_many => $class->meta->find_attribute_by_name($attr_name)->array,
            property_name => $attr_name);
    }

    return \@result;
}

sub _output_properties {
    my $class = shift;
    my @result;
    for my $attr_name ($class->outputs) {
        push @result, Procera::WorkflowCompatibility::FakeProperty::Output->new(
            property_name => $attr_name);
    }

    return \@result;
}

sub _param_properties {
    my $class = shift;
    my @result;
    for my $attr_name ($class->params) {
        push @result, Procera::WorkflowCompatibility::FakeProperty::Param->new(
            property_name => $attr_name);
    }

    return \@result;
}

sub dump_debug_messages {}
sub dump_error_messages {}
sub dump_status_messages {}
sub dump_warning_messages {}

sub __errors__ {}


1;
