package Procera::Compiler::AST::Node::Process;

use Moose;
use warnings FATAL => 'all';

use Carp qw(confess);
use List::MoreUtils qw(first_index);
use Params::Validate qw();
use Set::Scalar;
use Memoize;
use Genome;

use Procera::Compiler::AST::Node::Tool;
use Procera::Compiler::AST::Link;

extends 'Procera::Compiler::AST::Node';

has nodes => (
    is => 'ro',
    isa => 'ArrayRef[Procera::Compiler::AST::Node::Process|Procera::Compiler::AST::Node::Tool]',
    required => 1,
);
has links => (
    is => 'rw',
    isa => 'ArrayRef[Procera::Compiler::AST::Link]',
    default => sub {[]},
);

sub BUILD {
    my $self = shift;

    $self->uuid("cluster_" . $self->_new_uuid);
    $self->_set_missing_aliases;

    $self->_set_constants;
    $self->_set_params;

    $self->_make_explicit_inputs;
    $self->_make_explicit_outputs;
    $self->_make_explicit_links;
    return;
}

sub set_step_labels {
    my $self = shift;

    for my $param (values %{$self->params}) {
        if ($param->name =~ m/^(.*)\._step_label$/) {
            my $step_label = $1;
            $self->constants->{$param->name} = $step_label;
        }
    }
    return;
}

sub dag {
    my $self = shift;

    my $dag = Genome::WorkflowBuilder::DAG->create(
        name => $self->alias,
        parallel_by => $self->parallel,
    );

    for my $node (@{$self->nodes}) {
        $dag->add_operation($node->dag);
    }

    for my $link (@{$self->links}) {
        if ($link->source->node == $self) {
            $dag->connect_input(
                input_property => $link->source->name,
                destination => $link->destination->node->dag,
                destination_property => $link->destination->name,
            );
        } elsif ($link->destination->node == $self) {
            $dag->connect_output(
                output_property => $link->destination->name,
                source => $link->source->node->dag,
                source_property => $link->source->name,
            );
        } else {
            $dag->create_link(
                source => $link->source->node->dag,
                source_property => $link->source->name,
                destination => $link->destination->node->dag,
                destination_property => $link->destination->name,
            );
        }
    }
    return $dag;
}
Memoize::memoize('dag');

sub dot_nodes {
    my $self = shift;

    my @result;
    # input_connector
    push @result, sprintf('%s [label="@"];', $self->_new_uuid);

    for my $node (@{$self->nodes}) {
        push @result, @{$node->dot_nodes};
    }

    # output_connector
    push @result, sprintf('%s [label="@"];', $self->_new_uuid);

    return \@result;
}
Memoize::memoize('dot_nodes');

sub dot_links {
    my $self = shift;

    my @result;
    for my $node (@{$self->nodes}) {
        push @result, @{$node->dot_links};
    }

    for my $link (@{$self->links}) {
        my ($source_idx, $destination_idx) = (-1, 0);
        $source_idx = 0 if $link->source->node == $self;
        $destination_idx = -1 if $link->destination->node == $self;

        my $source_id = id_from_dot_node(
            @{$link->source->node->dot_nodes}[$source_idx]
        );
        my $destination_id = id_from_dot_node(
            @{$link->destination->node->dot_nodes}[$destination_idx]
        );
        push @result, sprintf('%s -> %s;', $source_id, $destination_id);
    }
    return \@result;
}

sub id_from_dot_node {
    my $dot_node = shift;
    return (split(/\s/, $dot_node))[0];
}

sub dot_cluster {
    my $self = shift;

    my @sub_clusters;
    for my $node (@{$self->nodes}) {
        push @sub_clusters, $node->dot_cluster if $node->dot_cluster;
    }

    my @node_ids;
    for my $dot_node (@{$self->dot_nodes}) {
        push @node_ids, id_from_dot_node($dot_node);
    }

    my $sub_clusters = join('; ', @sub_clusters) . ';' if @sub_clusters;
    my $node_ids = join('; ', @node_ids) . ';' if @node_ids;
    return sprintf('subgraph "cluster_%s" {label="%s"; %s %s}',
        $self->uuid,
        $self->alias,
        $sub_clusters || '',
        $node_ids || '',
    );
}

sub dot {
    my $self = shift;

    return sprintf("digraph G {\n%s\n%s\n%s\n}\n",
        join("\n", @{$self->dot_nodes}),
        join("\n", Set::Scalar->new(@{$self->dot_links})->members),
        join("\n", $self->dot_cluster),
    );
}

sub _set_constants {
    my $self = shift;

    my %constants;
    for my $node (@{$self->nodes}) {
        my %node_constants = %{$node->constants};
        for my $name (keys %node_constants) {
            my $data_end_point = $node->params->{$name};
            my $local_name = $self->_automatic_property_name($data_end_point);
            my $value = $node_constants{$name};
            $constants{$local_name} = $value;
        }
    }

    for my $coupler ($self->constant_couplers) {
        $constants{$coupler->name} = $coupler->value;
    }

    $self->constants(\%constants);
}

sub _set_params {
    my $self = shift;

    my %params;
    for my $node (@{$self->nodes}) {
        my %node_params = %{$node->params};
        for my $name (keys %node_params) {
            my $data_end_point = $node_params{$name};
            my $local_name = $self->_automatic_property_name($data_end_point);

            my $source = $self->_add_param(name => $local_name);
            $self->_link(source => $source, destination => $data_end_point);
        }
    }
    return;
}


sub _make_explicit_links {
    my $self = shift;

    my @links;
    for my $destination_node (@{$self->nodes}) {
        for my $coupler ($destination_node->internal_couplers) {
            my $destination_end_point = $destination_node->inputs->{$coupler->name};

            my $source_node = $self->_node_aliased($coupler->source_node_alias);

            my $source_end_point;
            if ($source_node->outputs->{$coupler->source_name}) {
                $source_end_point = $source_node->outputs->{$coupler->source_name};
            } else {
                confess sprintf("No output named (%s) on node %s (%s)",
                    $coupler->source_name, $source_node->source_path, $source_node->alias);
            }

            $self->_link(source => $source_end_point, destination => $destination_end_point);
        }
    }
    push @{$self->links}, @links;
}

sub _make_explicit_inputs {
    my $self = shift;

    my @links;
    for my $destination_node (@{$self->nodes}) {
        for my $coupler ($destination_node->input_couplers) {
            my $destination_end_point = $destination_node->inputs->{$coupler->name};

            my $source_end_point = $self->_find_or_add_input($coupler->input_name);
            $self->_link(source => $source_end_point, destination => $destination_end_point);
        }
    }
    push @{$self->links}, @links;
}

sub _find_or_add_input {
    my ($self, $name) = @_;

    my $existing_input = $self->inputs->{$name};
    unless (defined $existing_input) {
        $existing_input = $self->_add_input(name => $name);
    }
    return $existing_input;
}

sub _make_explicit_outputs {
    my $self = shift;

    my @links;
    for my $source_node (@{$self->nodes}) {
        for my $coupler ($source_node->output_couplers) {
            my $source_end_point = $source_node->outputs->{$coupler->name};

            my $destination_end_point = $self->_add_output(name => $coupler->output_name);
            $self->_link(source => $source_end_point, destination => $destination_end_point);
        }
    }
    push @{$self->links}, @links;
}


sub _node_aliased {
    my $self = shift;
    my $alias = shift;

    for my $node (@{$self->nodes}) {
        return $node if $node->alias eq $alias;
    }
    confess sprintf("No node found with alias (%s): [%s]",
        $alias, join(', ', map {sprintf("%s (%s)", $_->source_path, $_->alias)} @{$self->nodes}),
    );
}

sub _link {
    my $self = shift;
    my %params = Params::Validate::validate(@_, {
        source => 1,
        destination => 1,
    });
    push @{$self->links}, Procera::Compiler::AST::Link->new(
        source => $params{source},
        destination => $params{destination},
    );
    return;
}

sub _set_missing_aliases {
    my $self = shift;

    my $tree = $self->_build_alias_tree;
    for my $node (@{$self->nodes}) {
        next if $node->alias;
        my @path = $node->source_path_components;
        my $res = _find_leaf($tree, @path);
        $node->alias($res);
    }

    return;
}


sub _build_alias_tree {
    my $self = shift;

    my $tree = {};
    for my $node (@{$self->nodes}) {
        next if $node->alias;
        _insert_path($tree, $node->source_path_components);
    }

    return $tree;
}

sub _insert_path {
    my ($tree, $path) = @_;

    my $next = shift @$path;
    if (@$path) {
        _insert_path($tree->{$next}, $path);
    } else {
        $tree->{$next} = {};
    }

    return;
}

sub _find_leaf {
    my ($tree, $path) = @_;

    my $node = $tree;
    my $current_part = shift @$path;
    my @result = ($current_part);

    while (scalar(keys %{$node->{$current_part}}) > 1) {
        $node = $node->{$current_part};
        $current_part = shift @$path;
        push @result, $current_part;
    }

    return join('::', reverse @result);
}


sub _automatic_property_name {
    my ($self, $data_end_point) = @_;

    return sprintf("%s.%s", $data_end_point->node->alias,
        $data_end_point->name);
}


1;
