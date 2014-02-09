package Subject;

use Procera::Tool;
use warnings FATAL => 'all';

has_input 'some_input';
has_input 'another_input';

has_param 'some_param';
has_param 'another_param';

has_output 'some_output';
has_output 'another_output';

__PACKAGE__->meta->make_immutable;
