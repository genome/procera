package Procera::InputFile;

use Moose;
use warnings FATAL => 'all';

use Carp qw(confess);
use List::MoreUtils qw();
use IO::File qw();

use Procera::InputFile::Entry;
use Data::Dumper;

has entries => (
    is => 'rw',
    isa => 'ArrayRef[Procera::InputFile::Entry]',
    default => sub {[]},
);

sub create_from_filename {
    my ($class, $filename) = @_;

    my $fh = IO::File->new($filename, 'r');
    my $self = $class->create_from_file_handle($fh);
    $fh->close;

    return $self;
}

sub create_from_file_handle {
    my ($class, $file_handle) = @_;

    my @entries;
    for my $line (<$file_handle>) {
        push @entries, Procera::InputFile::Entry->create_from_line($line);
    }

    my $self = $class->new(entries => \@entries);

    return $self;
}


sub create_from_process_node {
    my ($class, $process) = @_;

    my @entries;
    for my $param_name (keys %{$process->params}) {
        push @entries, Procera::InputFile::Entry->new(
            name => $param_name,
            value => $process->constants->{$param_name},
        );
    }
    for my $input_name (keys %{$process->inputs}) {
        push @entries, Procera::InputFile::Entry->new(
            name => $input_name,
        );
    }

    my $self = $class->new(entries => \@entries);

    return $self;
}

sub write_to_filename {
    my ($self, $filename) = @_;

    my $fh = IO::File->new($filename, 'w');
    $self->write($fh);
    $fh->close;

    return;
}

sub write {
    my ($self, $file_handle) = @_;

    for my $entry (sort {$a->as_sortable_string cmp $b->as_sortable_string} @{$self->entries}) {
        $entry->write($file_handle);
    }

    return;
}

sub as_hash {
    my $self = shift;

    $self->validate_completeness;

    my %result;
    for my $entry (@{$self->entries}) {
        $result{$entry->name} = $entry->value;
    }

    return %result;
}

sub validate_completeness {
    my $self = shift;

    $self->_validate_no_duplicate_names;
    $self->_validate_no_missing_values;

    return;
}

sub _validate_no_missing_values {
    my $self = shift;

    for my $entry (@{$self->entries}) {
        $entry->assert_has_value;
    }

    return;
}

sub _validate_no_duplicate_names {
    my $self = shift;

    my %names;
    for my $entry (@{$self->entries}) {
        if (exists $names{$entry->name}) {
            confess sprintf("Duplciate input found for '%s'", $entry->name);
        } else {
            $names{$entry->name} = 1;
        }
    }

    return;
}

sub set_process {
    my ($self, $url) = @_;

    for my $entry (@{$self->entries}) {
        if ($entry->name =~ m/^.*\._process$/) {
            $self->set_inputs($entry->name, $url);
        }
    }
    return;
}

sub set_test_name {
    my ($self, $test_name) = @_;

    for my $entry (@{$self->entries}) {
        if ($entry->name =~ m/^.*\.test_name$/) {
            unless ($entry->has_value) {
                $self->set_inputs($entry->name, $test_name);
            }
        }
    }

    return;
}

sub set_inputs {
    my $self = shift;
    my %params = @_;

    for my $name (keys %params) {
        my $entry = $self->entry_named($name);
        $entry->value($params{$name});
        $entry->assert_has_value;
    }

    return;
}

sub entry_named {
    my ($self, $name) = @_;

    $self->_validate_no_duplicate_names;

    return List::MoreUtils::first_value {$_->name eq $name} @{$self->entries};
}


sub update {
    my ($self, $other) = @_;

    for my $other_entry (@{$other->entries}) {
        my $self_entry = $self->entry_named($other_entry->name);
        if (defined $self_entry) {
            $self_entry->value($other_entry->value);
        } else {
            push @{$self->entries}, $other_entry;
        }
    }

    return;
}


1;
