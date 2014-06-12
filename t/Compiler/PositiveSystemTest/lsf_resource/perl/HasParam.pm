package HasParam;
use Procera::Tool;
use warnings FATAL => 'all';

has_param 'p1';

sub lsf_resource {
    "-M 25000000 -R 'select[mem>25000] rusage[mem=25000]'",
}

__PACKAGE__->meta->make_immutable;
