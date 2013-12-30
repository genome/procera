package Procera::Persistence::Detail::Role;

use Moose::Role;
use warnings FATAL => 'all';


requires 'add_step_to_process';
requires 'create_fileset';
requires 'create_process';
requires 'create_result';
requires 'get_allocation_id_for_fileset';
requires 'get_file';
requires 'get_result';


1;
