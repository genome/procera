package A;
use Procera::Tool;
use warnings FATAL => 'all';

has_input 'ai1' => (array => 1);
has_output 'ao1';


__PACKAGE__->meta->make_immutable;
