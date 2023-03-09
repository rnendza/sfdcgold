<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Field_Assessment_Assigned</fullName>
        <description>Field Assessment Assigned</description>
        <protected>false</protected>
        <recipients>
            <field>Assigned_To__c</field>
            <type>contactLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Project/Field_Assessment_Assigned</template>
    </alerts>
    <alerts>
        <fullName>Send_Field_Assessment_Owner_Approval_Notification</fullName>
        <description>Send Field Assessment Owner Approval Notification</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderAddress>crm@accelentertainment.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Project/Field_Assessment_Approved</template>
    </alerts>
    <alerts>
        <fullName>Send_Field_Assessment_Owner_Rejection_Notification</fullName>
        <description>Send Field Assessment Owner Rejection Notification</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderAddress>crm@accelentertainment.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Project/Field_Assessment_Rejected</template>
    </alerts>
</Workflow>
