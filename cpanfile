requires 'perl' => '5.10.1';

requires "Data::UUID";
requires "File::Slurp";
requires "IO::Scalar";
requires "JSON";
requires "Log::Log4perl";
requires "Moose";
requires "MooseX::Getopt";
requires "Params::Validate";
requires "Readonly";
requires "Set::Scalar";
requires "Text::CSV";
requires "URI::URL";
requires "XML::LibXML";
requires "XML::Tidy";

on 'test' => sub {
  requires "Test::Exception";
};

# UR dependencies
requires 'Class::AutoloadCAN';
requires 'Class::Autouse';
requires 'Clone::PP';
requires 'DBI';
requires 'Data::UUID';
requires 'Date::Format';
requires 'FreezeThaw';
requires 'Lingua::EN::Inflect';

# Workflow dependencies
requires 'Date::Pcalc';
