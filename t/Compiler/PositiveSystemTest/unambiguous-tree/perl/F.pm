package F;
use Procera::Tool;
use warnings FATAL => 'all';


has_input 'fi1';
has_output 'fo1';


__PACKAGE__->meta->make_immutable;
