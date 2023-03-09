<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Update_Final_Approved_Indicator_To_False</fullName>
        <field>Final_Approved_Indicator__c</field>
        <literalValue>0</literalValue>
        <name>Update Final Approved Indicator To False</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Final_Approved_Indicator_To_True</fullName>
        <field>Final_Approved_Indicator__c</field>
        <literalValue>1</literalValue>
        <name>Update Final Approved Indicator To True</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_IR_Approved_Date</fullName>
        <field>IR_Approved_Date__c</field>
        <formula>Today()</formula>
        <name>Update IR Approved Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_IR_Submitted_Date</fullName>
        <field>Submitted_Date__c</field>
        <formula>Today()</formula>
        <name>Update IR Submitted Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Status_To_Open</fullName>
        <field>Status__c</field>
        <literalValue>Open</literalValue>
        <name>Update Status To Open</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Status_to_Approved_for_PO</fullName>
        <field>Status__c</field>
        <literalValue>Approved for PO</literalValue>
        <name>Update Status to Approved for PO</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Status_to_Pending_Approval</fullName>
        <field>Status__c</field>
        <literalValue>IR Request Pending Approval</literalValue>
        <name>Update Status to Pending Approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
</Workflow>
