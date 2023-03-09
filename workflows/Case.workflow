<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Parts_Request_hasn_t_been_addressed_in_over_48_hours</fullName>
        <description>Parts Request hasn&apos;t been addressed in over 48 hours</description>
        <protected>false</protected>
        <recipients>
            <recipient>Parts_Department</recipient>
            <type>role</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Opportunity_Email_Templates/Brad_Shapirro</template>
    </alerts>
    <fieldUpdates>
        <fullName>Software_Upgrade_Approved</fullName>
        <field>Software_Upgrade_Approved__c</field>
        <literalValue>1</literalValue>
        <name>Software Upgrade Approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Swap_Approved</fullName>
        <field>Swap_Approved__c</field>
        <literalValue>1</literalValue>
        <name>Swap Approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Addition_Approved</fullName>
        <field>Addition_Approved__c</field>
        <literalValue>1</literalValue>
        <name>Update Addition Approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Status_to_Approved</fullName>
        <field>Status_AddSwapRequest__c</field>
        <literalValue>Approved</literalValue>
        <name>Update Status to Approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Status_to_Denied</fullName>
        <field>Status_AddSwapRequest__c</field>
        <literalValue>Denied</literalValue>
        <name>Update Status to Denied</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Status_to_Pending_Compliance_Appr</fullName>
        <field>Status_AddSwapRequest__c</field>
        <literalValue>Pending Compliance Approval</literalValue>
        <name>Update Status to Pending Compliance Appr</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Status_to_Pending_Regional_Approv</fullName>
        <field>Status_AddSwapRequest__c</field>
        <literalValue>Pending Regional Approval</literalValue>
        <name>Update Status to Pending Regional Approv</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <tasks>
        <fullName>Update_Asset_for_Swap</fullName>
        <assignedTo>accel@penrodsoftware.com</assignedTo>
        <assignedToType>user</assignedToType>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Open</status>
        <subject>Update Asset for Swap</subject>
    </tasks>
</Workflow>
