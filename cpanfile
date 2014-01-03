requires 'perl' => '5.10.1';

requires "Data::UUID";
requires "File::Slurp";
requires "IO::Scalar";
requires "JSON";
requires "Log::Log4perl";
requires "Moose";
requires "Params::Validate";
requires "URI::URL";
requires "XML::LibXML";

on 'test' => sub {
  requires "Test::Exception";
};
