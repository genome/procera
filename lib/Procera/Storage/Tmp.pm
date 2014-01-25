package Procera::Storage::Tmp;

use MooseX::Singleton;
use warnings FATAL => 'all';

with 'Procera::Storage::Detail::Role';

use Data::UUID qw();
use File::Basename qw();
use File::Copy qw();
use File::Path qw();
use File::Spec qw();
use File::Temp qw();
use POSIX qw();


has _allocations => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
);

has _base_path => (
    is => 'ro',
    isa => 'Object',
    default => sub {
        return File::Temp->newdir();
    },
);

sub save_files {
    my $self = shift;

    my $total_size = 0;
    for my $file (@_) {
        unless (-f $file) {
            Carp::confess(sprintf("'%s' is not a file.", $file));
        }
        my $file_size = POSIX::ceil((-s $file) / 1024);
        $total_size += $file_size;
    }

    my $allocation = $self->create_allocation($total_size);

    for my $file (@_) {
        _copy($file, File::Spec->join($allocation->{absolute_path}, $file));
    }

    return $allocation->{id};
}

sub create_allocation {
    my ($self, $kilobytes_requested) = @_;

    my $id = Data::UUID->new->create_hex;
    my $absolute_path = File::Spec->join($self->_base_path->dirname, $id);

    File::Path::make_path($absolute_path);

    return { id => $id, absolute_path => $absolute_path };
}

sub _copy {
    my ($source, $destination) = @_;

    _make_path_to($destination);
    File::Copy::cp($source, $destination);

    return;
}

sub _make_path_to {
    my $full_path = shift;

    my ($file, $path) = File::Basename::fileparse($full_path);
    File::Path::make_path($path);

    return;
}

sub get_copy_path {
    my ($self, $allocation, $path) = @_;

    return File::Spec->join($self->_base_path->dirname,
            $allocation->{allocation_id}, $path);
}


__PACKAGE__->meta->make_immutable;
