package Procera::InputFile::Entry;

use Moose;
use warnings FATAL => 'all';

use Carp qw(confess);

use Text::CSV qw();
use Memoize qw();

has name => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);
has value => (
    is => 'rw',
    isa => 'ArrayRef|Value|Undef',
    predicate => 'has_value',
);

sub assert_has_value {
    my $self = shift;

    unless (defined($self->value)) {
        confess sprintf("Input entry %s has no value",
            $self->name);
    }

    return;
}

my $_CSV = Text::CSV->new({binary => 1, sep_char => "\t"});
sub write {
    my ($self, $file_handle) = @_;

    printf $file_handle "%s\n", $self->as_string;

    return;
}

sub as_string {
    my $self = shift;

    my @columns = ($self->name);
    if (defined($self->value)) {
        if (ref($self->value) eq 'ARRAY') {
            push @columns, @{$self->value};
        } else {
            push @columns, $self->value;
        }
    }

    $_CSV->combine(@columns);
    return $_CSV->string;
}
Memoize::memoize('as_string');

sub as_sortable_string {
    my $self = shift;

    (my $sortable_string = $self->as_string) =~ s/STEP_LABEL_[^\t]*/STEP_LABEL_1/;
    return $sortable_string;
}

sub create_from_line {
    my ($class, $line) = @_;

    unless ($_CSV->parse($line)) {
        confess sprintf("Failed to parse line: %s", $line);
    }
    my @columns = $_CSV->fields;

    unless (scalar(@columns) > 0) {
        confess sprintf(
            "Bad number of columns (%s) in line, expected 1 or more: [%s]",
            scalar(@columns), join(', ', map {sprintf("'%s'", $_)} @columns));
    }

    my $name = shift @columns;
    if (scalar(@columns) == 1) {
        return $class->new(name => $name, value => $columns[0]);
    } elsif (scalar(@columns) > 1) {
        return $class->new(name => $name, value => \@columns);
    } else {
        return $class->new(name => $name);
    }
}

1;
