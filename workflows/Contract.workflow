<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>BDM_is_Notified</fullName>
        <description>BDM is Notified</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Opportunity_Email_Templates/BDM_Addendum_Signed</template>
    </alerts>
    <alerts>
        <fullName>New_ATM_Contract_Notification</fullName>
        <description>New ATM Contract Notification</description>
        <protected>false</protected>
        <recipients>
            <recipient>kurtg@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Contract/New_Contract</template>
    </alerts>
    <alerts>
        <fullName>New_Extension_Contract_Notification</fullName>
        <description>New Extension Contract Notification</description>
        <protected>false</protected>
        <recipients>
            <recipient>donnag@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Contract/New_Contract</template>
    </alerts>
    <alerts>
        <fullName>Notify_due_diligence_of_upload_of_TUA_or_Extension</fullName>
        <description>Notify due diligence of upload of TUA or Extension</description>
        <protected>false</protected>
        <recipients>
            <recipient>samanthaw@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/New_TUA_or_Extension</template>
    </alerts>
    <fieldUpdates>
        <fullName>Approved</fullName>
        <field>Status</field>
        <literalValue>Active</literalValue>
        <name>Approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>In_Approval</fullName>
        <field>Status</field>
        <literalValue>In Approval</literalValue>
        <name>In Approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Rejected</fullName>
        <field>Status</field>
        <literalValue>Rejected</literalValue>
        <name>Rejected</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Stage_Approved</fullName>
        <field>Status</field>
        <literalValue>Active</literalValue>
        <name>Stage Approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Stage_Rejected</fullName>
        <field>Status</field>
        <literalValue>Rejected</literalValue>
        <name>Stage Rejected</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
</Workflow>
