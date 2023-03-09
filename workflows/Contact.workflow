<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Portal_User_Creation_Notification_to_RM</fullName>
        <description>Portal User Creation Notification to RM</description>
        <protected>false</protected>
        <recipients>
            <field>Account_RM__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Portal_Contact_was_Created</template>
    </alerts>
    <alerts>
        <fullName>SA_Delisted_Date_changed_Alert</fullName>
        <description>SA Delisted Date changed Alert</description>
        <protected>false</protected>
        <recipients>
            <recipient>HR_Employee_Sales_Agent_Status_Alert</recipient>
            <type>group</type>
        </recipients>
        <senderAddress>crm@accelentertainment.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/SA_Delisted_Date_Update</template>
    </alerts>
    <alerts>
        <fullName>SA_Registered_Date_changed_Alert</fullName>
        <description>SA Registered Date changed Alert</description>
        <protected>false</protected>
        <recipients>
            <recipient>HR_Employee_Sales_Agent_Status_Alert</recipient>
            <type>group</type>
        </recipients>
        <senderAddress>crm@accelentertainment.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/SA_Registered_Date_Update</template>
    </alerts>
</Workflow>
