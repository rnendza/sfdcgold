<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Lead_Approved_Notification</fullName>
        <description>Lead Approved Notification</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Lead_Email_Templates_Folder/Lead_Approved_Notification</template>
    </alerts>
    <alerts>
        <fullName>Lead_Authorization_Request</fullName>
        <description>Lead Authorization Request</description>
        <protected>false</protected>
        <recipients>
            <recipient>pennys@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>samanthaw@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Lead_Email_Templates_Folder/Lead_Authorization_Request</template>
    </alerts>
    <alerts>
        <fullName>Lead_Authorization_Request_GA_NE_NC_only</fullName>
        <description>Lead Authorization Request (GA, NE, NC only)</description>
        <protected>false</protected>
        <recipients>
            <recipient>robertm@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Lead_Email_Templates_Folder/Lead_Authorization_Request</template>
    </alerts>
    <alerts>
        <fullName>Lead_Authorization_Request_IL</fullName>
        <description>Lead Authorization Request (IL only)</description>
        <protected>false</protected>
        <recipients>
            <recipient>lainel@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>lashays@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Lead_Email_Templates_Folder/Lead_Authorization_Request</template>
    </alerts>
    <alerts>
        <fullName>New_Lead_Alert</fullName>
        <description>New Lead Alert</description>
        <protected>false</protected>
        <recipients>
            <recipient>samanthaw@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Lead_Email_Templates_Folder/New_Lead_Notification</template>
    </alerts>
    <alerts>
        <fullName>New_lead_submission_notification</fullName>
        <ccEmails>leads@accelentertainment.com</ccEmails>
        <description>New lead submission notification</description>
        <protected>false</protected>
        <senderType>CurrentUser</senderType>
        <template>Lead_Email_Templates_Folder/Lead_Authorization_Request</template>
    </alerts>
    <fieldUpdates>
        <fullName>Mark_Lead_Approved</fullName>
        <field>Lead_Approved__c</field>
        <literalValue>1</literalValue>
        <name>Mark Lead Approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Status_to_Lead_Auth</fullName>
        <field>Status</field>
        <literalValue>Lead Authorization</literalValue>
        <name>Status to Lead Auth</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Status_to_Lead_Qualification</fullName>
        <field>Status</field>
        <literalValue>Lead Qualification</literalValue>
        <name>Status to Lead Qualification</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
</Workflow>
