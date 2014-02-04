use strict;
use warnings FATAL => 'all';

use Test::More;
use File::Temp;

use_ok('Procera::InputFile');

my $hashref = {
    single => 5,
    array => [5, 4, 3],
    quotes => 'This thing "has" quotes and ({special, characters})',
};
my $input_file = Procera::InputFile->create_from_hashref($hashref);

my %rt_hash = $input_file->as_hash();
is_deeply(\%rt_hash, $hashref, 'Can roundtrip a hash through an InputFile object');


my $tempdir = File::Temp::tempdir(CLEANUP => 1);
my $full_path = File::Spec->join($tempdir, 'inputs.tsv');
$input_file->write_to_filename($full_path);

my $rt_input_file = Procera::InputFile->create_from_filename($full_path);
my %file_rt_hash = $rt_input_file->as_hash();
is_deeply(\%file_rt_hash, $hashref, 'Can roundtrip a hash through a file');

done_testing();
