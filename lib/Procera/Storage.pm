package Procera::Storage;

use Moose;
use warnings FATAL => 'all';

use Data::UUID qw();
use File::Basename qw();
use File::Copy qw();
use File::Path qw();
use File::Spec qw();

use POSIX qw(ceil);

use Genome;


sub save_files {
    my $self = shift;

    my $total_size = 0;
    for my $file (@_) {
        unless (-f $file) {
            Carp::confess(sprintf("'%s' is not a file.", $file));
        }
        my $file_size = ceil((-s $file) / 1024);
        $total_size += $file_size;
    }

    my $allocation = $self->create_allocation($total_size);

    for my $file (@_) {
        _copy($file, File::Spec->join($allocation->absolute_path, $file));
    }

    return $allocation->id;
}

sub create_allocation {
    my ($self, $kilobytes_requested) = @_;

    my $owner = Genome::Sys->current_user;
    return Genome::Disk::Allocation->create(
        allocation_path => _generate_allocation_path(),
        disk_group_name => 'info_genome_models',
        owner_class_name => $owner->class,
        owner_id => $owner->id,
        kilobytes_requested => $kilobytes_requested,
    );
}

sub _generate_allocation_path {
    my $uuid = Data::UUID->new->create_hex;
    return File::Spec->join('model_data',
        substr($uuid, 2, 3), substr($uuid, 5));
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

    return File::Spec->join(
        Genome::Disk::Allocation->get(
            $allocation->{allocation_id})->absolute_path, $path);
}


__PACKAGE__->meta->make_immutable;
