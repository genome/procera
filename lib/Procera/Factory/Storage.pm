package Procera::Factory::Storage;

use strict;
use warnings FATAL => 'all';


use Carp qw();
use Memoize qw();


my %_TYPE_MAP = (
    'allocation' => 'Procera::Storage::Allocation',
    'tmp' => 'Procera::Storage::Tmp',
);
sub create {
    my $type = shift;

    my $class = $_TYPE_MAP{$type};

    eval "use $class";
    if ($@) {
        Carp::confess(sprintf(
                "Failed to load storage class '%s' for type '%s'",
                $class, $type));
    }

    return $class->new(@_);
}
Memoize::memoize('create');


1;
