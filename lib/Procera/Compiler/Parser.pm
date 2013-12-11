package Procera::Compiler::Parser;

use strict;
use warnings 'FATAL' => 'all';

use Carp qw(confess);

use File::Basename qw();
use File::Spec qw();
use File::Slurp qw();

use Parse::RecDescent qw();
use Procera::Compiler::AST::NodeFactory;
use Procera::Compiler::AST::Node::IO::Process;
use Procera::Compiler::AST::Coupler::Input;
use Procera::Compiler::AST::Coupler::Output;
use Procera::Compiler::AST::Coupler::Internal;
use Procera::Compiler::AST::Coupler::Constant;
use Procera::Compiler::AST::Coupler::Converge;


sub new_process {
    my $definition_path = shift;
    my $source_path = shift;

    my $startup_actions = sprintf('{my $root_source_path = q(%s)}' . "\n", $source_path);

    return _parse_tree_generator($startup_actions)->start(_slurp_scalar($definition_path))
        or confess "Syntax error";
}

sub _parse_tree_generator {
    my $startup_actions = shift || '';

    return new Parse::RecDescent($startup_actions . _slurp_scalar(_grammar_path()))
        or confess "Illegal grammar";
}

sub _grammar_path {
    return File::Spec->join(_base_path(), 'gms.grammar');
}

sub _base_path {
    return File::Basename::dirname(File::Spec->rel2abs(__FILE__));
}

sub _slurp_scalar {
    my $input_path = shift;

    my $force_scalar = File::Slurp::read_file($input_path);
    return $force_scalar;
}

1;
