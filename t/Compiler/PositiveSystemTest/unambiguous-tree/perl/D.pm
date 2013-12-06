package D;
use Procera::Tool;
use warnings FATAL => 'all';


has_input 'di1';
has_output 'do1';


__PACKAGE__->meta->make_immutable;
