requires 'perl' => '5.10.1';

requires "Data::UUID";
requires "File::Slurp";
requires "JSON";
requires "Log::Log4Perl";
requires "Moose";
requires "Params::Validate";
requires "URI::URL";
requires "XML::LibXML";  # for workflow builder

on 'test' => sub {
  requires "Test::Exception";
};
