package Procera::Tool;
use Moose qw();
use warnings FATAL => 'all';

use Moose::Exporter;
use Procera::Tool::Detail::AttributeSetter;


Moose::Exporter->setup_import_methods(
    also => ['Moose', 'Procera::Tool::Detail::AttributeSetter'],
);


sub init_meta {
    shift;
    return Moose->init_meta(@_, base_class => 'Procera::Tool::Detail::Base');
}


1;
