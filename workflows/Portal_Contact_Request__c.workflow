<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>PCR_Rejected_Notification_to_Requestor</fullName>
        <description>PCR Rejected Notification to Requestor</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/PCR_Rejected</template>
    </alerts>
    <alerts>
        <fullName>PCR_Submitted_Notification_to_PortalSupport_Monday_com</fullName>
        <ccEmails>accel-entertainment_board_2303262676_7d73283a4ddf41e87eac__22965109@use1.mx.monday.com</ccEmails>
        <description>PCR Submitted Notification to @PortalSupport &amp; Monday.com</description>
        <protected>false</protected>
        <recipients>
            <field>Portal_Support_Ticketing_System__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>crm@accelentertainment.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/PCR_Submitted</template>
    </alerts>
</Workflow>
