package Procera::Tool::Detail::Output;

use Moose::Role;
use warnings FATAL => 'all';

Moose::Util::meta_attribute_alias('Output');

has save => (
    is => 'ro',
    isa => 'Bool',
    default => sub {1},
);


1;
