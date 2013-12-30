package Procera::Factory::Persistence;

use strict;
use warnings FATAL => 'all';


use Carp qw();
use Memoize qw();


my %_TYPE_MAP = (
    'amber' => 'Procera::Persistence::Amber',
    'memory' => 'Procera::Persistence::Memory',
);
sub create {
    my $type = shift;

    my $class = $_TYPE_MAP{$type};

    eval "use $class";
    if ($@) {
        Carp::confess(sprintf(
                "Failed to load persistence class '%s' for type '%s'",
                $class, $type));
    }

    return $class->new(@_);
}
Memoize::memoize('create');


1;
