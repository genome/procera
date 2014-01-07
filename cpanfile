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

requires "Class::Autouse";
requires "Class::AutoloadCAN";
requires "Clone::PP";
requires "Lingua::EN::Inflect";
requires "Date::Pcalc";
requires "Guard";
requires "IPC::Run";
requires "GraphViz";
requires "Net::Statsd";
requires "Date::Format";
requires "DBI";
requires "FreezeThaw";
requires "XML::Simple";

on 'test' => sub {
  requires "Test::Exception";
};
