use strict;
use warnings;

use Test::More;

BEGIN {
    $ENV{TEST_WORKFLOW_BUILDER_QUEUE} = 'sample_queue';
};

use_ok('Procera::WorkflowBuilder::Command');
use_ok('Procera::WorkflowBuilder::Converge');
use_ok('Procera::WorkflowBuilder::DAG');

subtest 'Simple DAG' => sub {
    my $dag = Procera::WorkflowBuilder::DAG->new(
        name => 'top level',
        log_dir => '/tmp',
    );

    my $op = Procera::WorkflowBuilder::Command->new(
        name => 'some op',
        command => 'WorkflowBuilder::Test::DummyCommand',
    );
    $dag->add_operation($op);

    $dag->connect_input(
        input_property => 'some_external_input',
        destination => $op,
        destination_property => 'input',
    );
    $dag->connect_output(
        output_property => 'some_external_output',
        source => $op,
        source_property => 'single_output',
    );

    my $expected_xml = <<EOS;
<?xml version="1.0"?>
<operation name="top level" logDir="/tmp">
  <operationtype typeClass="Workflow::OperationType::Model">
    <inputproperty>some_external_input</inputproperty>
    <outputproperty>some_external_output</outputproperty>
  </operationtype>
  <operation name="some op">
    <operationtype typeClass="Workflow::OperationType::Command" lsfQueue="$ENV{TEST_WORKFLOW_BUILDER_QUEUE}" lsfResource="-M 25000000 -R 'select[mem&gt;25000] rusage[mem=25000]'" commandClass="WorkflowBuilder::Test::DummyCommand">
      <inputproperty>input</inputproperty>
      <outputproperty>many_output</outputproperty>
      <outputproperty>single_output</outputproperty>
    </operationtype>
  </operation>
  <link fromOperation="input connector" fromProperty="some_external_input" toOperation="some op" toProperty="input"/>
  <link fromOperation="some op" fromProperty="single_output" toOperation="output connector" toProperty="some_external_output"/>
</operation>
EOS

    is($dag->get_xml, $expected_xml, 'simple dag produces expected xml');
};

subtest 'Invalid DAG Name' => sub {
    my $dag = Procera::WorkflowBuilder::DAG->new(name => 'input connector');

    eval {
        diag "Expect one error message about invalid operation name:";
        $dag->validate;
    };

    ok($@, 'invalid operation name fails to validate');
};

subtest 'Non-Unique Operation Names' => sub {
    my $dag = Procera::WorkflowBuilder::DAG->new(name => 'top level');

    my $op1 = Procera::WorkflowBuilder::Command->new(
        name => 'duplicate name',
        command => 'WorkflowBuilder::Test::DummyCommand'
    );
    $dag->add_operation($op1);

    my $op2 = Procera::WorkflowBuilder::Command->new(
        name => 'duplicate name',
        command => 'WorkflowBuilder::Test::DummyCommand'
    );
    $dag->add_operation($op2);

    eval {
        diag "Expect one error message about duplicate operation name";
        $dag->validate;
    };

    ok($@, 'duplicate operation names not allowed');
};

subtest 'Unowned Operations' => sub {
    my $dag = Procera::WorkflowBuilder::DAG->new(name => 'top level');

    my $owned_op = Procera::WorkflowBuilder::Command->new(
        name => 'owned op',
        command => 'WorkflowBuilder::Test::DummyCommand'
    );
    $dag->add_operation($owned_op);

    my $unowned_op = Procera::WorkflowBuilder::Command->new(
        name => 'unowned op',
        command => 'WorkflowBuilder::Test::DummyCommand'
    );

    $dag->create_link(
        source => $owned_op,
        source_property => 'single_output',
        destination => $unowned_op,
        destination_property => 'input'
    );

    eval {
        diag "Expect one error message about unowned operations";
        $dag->validate;
    };

    ok($@, 'unowned operations not allowed in dag links');
};

subtest 'Mandatory Inputs' => sub {
    my $dag = Procera::WorkflowBuilder::DAG->new(name => 'top level');

    my $op = Procera::WorkflowBuilder::Command->new(
        name => 'some op',
        command => 'WorkflowBuilder::Test::DummyCommand'
    );
    $dag->add_operation($op);

    eval {
        diag 'Expect one error message about missing operation inputs';
        $dag->validate();
    };

    ok($@, 'missing mandatory inputs not allowed in dag');
};

subtest 'Conflicting Inputs' => sub {
    my $dag = Procera::WorkflowBuilder::DAG->new(name => 'top level');

    my $op = Procera::WorkflowBuilder::Command->new(
        name => 'some op',
        command => 'WorkflowBuilder::Test::DummyCommand'
    );
    $dag->add_operation($op);

    $dag->connect_input(
        input_property => 'external_input_a',
        destination => $op,
        destination_property => 'input',
    );

    $dag->connect_input(
        input_property => 'external_input_b',
        destination => $op,
        destination_property => 'input',
    );

    eval {
        diag 'Expect one error message about conflicting operation inputs';
        $dag->validate();
    };

    ok($@, 'conflicting inputs not allowed in dag');
};

subtest 'XML Round Trip' => sub {
    my $xml = <<EOS;
<?xml version="1.0"?>
<operation name="top level" parallelBy="some_external_input" logDir="/tmp">
  <operationtype typeClass="Workflow::OperationType::Model">
    <inputproperty>some_external_input</inputproperty>
    <outputproperty>some_external_output</outputproperty>
  </operationtype>
  <operation name="some op">
    <operationtype typeClass="Workflow::OperationType::Command" lsfQueue="$ENV{TEST_WORKFLOW_BUILDER_QUEUE}" lsfResource="-M 25000000 -R 'select[mem&gt;25000] rusage[mem=25000]'" commandClass="WorkflowBuilder::Test::DummyCommand">
      <inputproperty>input</inputproperty>
      <outputproperty>many_output</outputproperty>
      <outputproperty>single_output</outputproperty>
    </operationtype>
  </operation>
  <link fromOperation="input connector" fromProperty="some_external_input" toOperation="some op" toProperty="input"/>
  <link fromOperation="some op" fromProperty="single_output" toOperation="output connector" toProperty="some_external_output"/>
</operation>
EOS

    my $dag = Procera::WorkflowBuilder::DAG->from_xml($xml);
    is($dag->get_xml, $xml, 'xml round trip');
};

subtest 'Converge XML Round Trip' => sub {
    my $xml = <<EOS;
<?xml version="1.0"?>
<operation name="top level" parallelBy="some_external_input" logDir="/tmp">
  <operationtype typeClass="Workflow::OperationType::Model">
    <inputproperty>external_input_0</inputproperty>
    <inputproperty>external_input_1</inputproperty>
    <outputproperty>external_output</outputproperty>
  </operationtype>
  <operation name="some op">
    <operationtype typeClass="Workflow::OperationType::Converge">
      <inputproperty>input_0</inputproperty>
      <inputproperty>input_1</inputproperty>
      <outputproperty>converge_output</outputproperty>
    </operationtype>
  </operation>
  <link fromOperation="input connector" fromProperty="external_input_0" toOperation="some op" toProperty="input_0"/>
  <link fromOperation="input connector" fromProperty="external_input_1" toOperation="some op" toProperty="input_1"/>
  <link fromOperation="some op" fromProperty="converge_output" toOperation="output connector" toProperty="external_output"/>
</operation>
EOS

    my $dag = Procera::WorkflowBuilder::DAG->from_xml($xml);
    is($dag->get_xml, $xml, 'xml round trip');
};

subtest 'Converge DAG' => sub {
    my $xml = <<EOS;
<?xml version="1.0"?>
<operation name="top level">
  <operationtype typeClass="Workflow::OperationType::Model">
    <inputproperty>external_input_0</inputproperty>
    <inputproperty>external_input_1</inputproperty>
    <outputproperty>external_output</outputproperty>
  </operationtype>
  <operation name="some op">
    <operationtype typeClass="Workflow::OperationType::Converge">
      <inputproperty>input_1</inputproperty>
      <inputproperty>input_0</inputproperty>
      <outputproperty>converge_output</outputproperty>
    </operationtype>
  </operation>
  <link fromOperation="input connector" fromProperty="external_input_0" toOperation="some op" toProperty="input_0"/>
  <link fromOperation="input connector" fromProperty="external_input_1" toOperation="some op" toProperty="input_1"/>
  <link fromOperation="some op" fromProperty="converge_output" toOperation="output connector" toProperty="external_output"/>
</operation>
EOS

    my $dag = Procera::WorkflowBuilder::DAG->new(name => 'top level');
    my $converge = $dag->add_operation(
        Procera::WorkflowBuilder::Converge->new(name => 'some op'));
    $dag->connect_input(input_property => 'external_input_1',
        destination => $converge, destination_property => 'input_1');
    $dag->connect_input(input_property => 'external_input_0',
        destination => $converge, destination_property => 'input_0');

    $dag->connect_output(output_property => 'external_output',
        source => $converge, source_property => 'converge_output');

    is($dag->get_xml, $xml, 'xml round trip');
};

done_testing();
