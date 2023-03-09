<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Marketing_Notify_regarding_backordered_item</fullName>
        <description>Marketing: Notify regarding backordered item</description>
        <protected>false</protected>
        <recipients>
            <field>Requestor_Email__c</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Marketing_Backordered_Item</template>
    </alerts>
    <alerts>
        <fullName>Notify_requestor_when_standard_marketing_items_complete</fullName>
        <description>Notify requestor when standard marketing items complete</description>
        <protected>false</protected>
        <recipients>
            <field>Requestor_Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>crm@accelentertainment.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Marketing_Email_Templates/Standard_request_filled</template>
    </alerts>
</Workflow>
