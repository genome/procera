package B;
use Procera::Tool;
use warnings FATAL => 'all';

has_input 'bi1';
has_input 'bi2';
has_input 'bi3';
has_output 'bo1';


__PACKAGE__->meta->make_immutable;
