use strict;
use warnings FATAL => 'all';;

use Test::More;

BEGIN {
    $ENV{TEST_WORKFLOW_BUILDER_QUEUE} = 'sample_queue';
};

use_ok('Procera::WorkflowBuilder::Command');

subtest 'Typical Command' => sub {
    my $op = Procera::WorkflowBuilder::Command->new(
        name => 'some op',
        command => 'WorkflowBuilder::Test::DummyCommand'
    );

    my $expected_xml = <<EOS;
<?xml version="1.0"?>
<operation name="some op">
  <operationtype typeClass="Workflow::OperationType::Command" lsfQueue="$ENV{TEST_WORKFLOW_BUILDER_QUEUE}" lsfResource="-M 25000000 -R 'select[mem&gt;25000] rusage[mem=25000]'" commandClass="WorkflowBuilder::Test::DummyCommand">
    <inputproperty>input</inputproperty>
    <outputproperty>many_output</outputproperty>
    <outputproperty>single_output</outputproperty>
  </operationtype>
</operation>
EOS

    is($op->get_xml, $expected_xml, 'typical command produces expected xml');
};

subtest 'Parallel-By Command' => sub {
    my $op = Procera::WorkflowBuilder::Command->new(
        name => 'some op',
        command => 'WorkflowBuilder::Test::DummyCommand',
        parallel_by => 'input',
    );

    my $expected_xml = <<EOS;
<?xml version="1.0"?>
<operation name="some op" parallelBy="input">
  <operationtype typeClass="Workflow::OperationType::Command" lsfQueue="$ENV{TEST_WORKFLOW_BUILDER_QUEUE}" lsfResource="-M 25000000 -R 'select[mem&gt;25000] rusage[mem=25000]'" commandClass="WorkflowBuilder::Test::DummyCommand">
    <inputproperty>input</inputproperty>
    <outputproperty>many_output</outputproperty>
    <outputproperty>single_output</outputproperty>
  </operationtype>
</operation>
EOS

    is($op->get_xml, $expected_xml, 'parallelBy command produces expected xml');
};

subtest 'Invalid Parallel-By Command' => sub {
    my $op = Procera::WorkflowBuilder::Command->new(
        name => 'some op',
        command => 'WorkflowBuilder::Test::DummyCommand',
        parallel_by => 'invalid_input',
    );

    eval {
        diag "Expect one error message about failing to validate inputs here:";
        $op->validate;
    };

    ok($@, "parallelBy on non input_property doesn't validate");
};

subtest 'Invalid Command Name' => sub {
    my $op = Procera::WorkflowBuilder::Command->new(
        name => 'input connector',
        command => 'WorkflowBuilder::Test::DummyCommand',
    );

    eval {
        diag "Expect one error message about invalid operation name:";
        $op->validate;
    };

    ok($@, 'invalid operation name fails to validate');
};

subtest 'XML Round Trip' => sub {
    my $xml = <<EOS;
<?xml version="1.0"?>
<operation name="some op" parallelBy="input">
  <operationtype typeClass="Workflow::OperationType::Command" lsfQueue="$ENV{TEST_WORKFLOW_BUILDER_QUEUE}" lsfResource="-M 25000000 -R 'select[mem&gt;25000] rusage[mem=25000]'" commandClass="WorkflowBuilder::Test::DummyCommand">
    <inputproperty>input</inputproperty>
    <outputproperty>many_output</outputproperty>
    <outputproperty>single_output</outputproperty>
  </operationtype>
</operation>
EOS

    my $op = Procera::WorkflowBuilder::Command->from_xml($xml);
    is($op->get_xml, $xml, 'xml round trip');
};

subtest 'unspecified_operation_type_attributes' => sub {
    my $op = Procera::WorkflowBuilder::Command->new(
        name => 'some op',
        command => 'WorkflowBuilder::Test::DummyCommand',
    );
    my %got = $op->operation_type_attributes;
    my %expected = (
        lsfQueue => $ENV{TEST_WORKFLOW_BUILDER_QUEUE},
        lsfResource => "-M 25000000 -R 'select[mem>25000] rusage[mem=25000]'",
        commandClass => 'WorkflowBuilder::Test::DummyCommand',
    );
    is_deeply(\%got, \%expected, 'got attributes from command');
};

subtest 'specified_operation_type_attributes' => sub {
    my $op = Procera::WorkflowBuilder::Command->new(
        name => 'some op',
        command => 'WorkflowBuilder::Test::DummyCommand',
    );
    $op->lsf_queue(sprintf('not %s', $ENV{TEST_WORKFLOW_BUILDER_QUEUE}));
    $op->lsf_project('specified project');
    my %got = $op->operation_type_attributes;
    my %expected = (
        lsfQueue => "not $ENV{TEST_WORKFLOW_BUILDER_QUEUE}",
        lsfResource => "-M 25000000 -R 'select[mem>25000] rusage[mem=25000]'",
        lsfProject => 'specified project',
        commandClass => 'WorkflowBuilder::Test::DummyCommand',
    );
    is_deeply(\%got, \%expected, 'got attributes as specified first, then from command');
};


done_testing();
