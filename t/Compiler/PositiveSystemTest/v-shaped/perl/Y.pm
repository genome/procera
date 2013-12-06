package Y;
use Procera::Tool;
use warnings FATAL => 'all';

has_input 'y_in_1';
has_input 'y_in_2';

has_output 'y_out_1';


__PACKAGE__->meta->make_immutable;
