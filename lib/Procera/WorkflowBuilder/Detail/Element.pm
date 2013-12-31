package Procera::WorkflowBuilder::Detail::Element;
use Moose::Role;
use warnings FATAL => 'all';


requires 'get_xml';
requires 'get_xml_element';
requires 'validate';


1;
