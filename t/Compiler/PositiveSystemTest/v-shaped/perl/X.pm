package X;
use Procera::Tool;
use warnings FATAL => 'all';

has_input 'x_in_1';
has_output 'x_out_1';


__PACKAGE__->meta->make_immutable;
