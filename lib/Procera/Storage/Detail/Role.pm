package Procera::Storage::Detail::Role;

use Moose::Role;
use warnings FATAL => 'all';


requires 'create_allocation';
requires 'get_copy_path';
requires 'save_files';


1;
