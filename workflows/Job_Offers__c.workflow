<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Job_Offer_Status_is_changed_to_No_Longer_Onboarding</fullName>
        <ccEmails>OpenReqs@Accelentertainment.com</ccEmails>
        <description>Job Offer Status is changed to No Longer Onboarding</description>
        <protected>false</protected>
        <recipients>
            <recipient>alyssam@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>daniellep@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>kurtg@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>maxs@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>nataliek@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>roys@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>saml@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderAddress>crm@accelentertainment.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Human_Resources/Job_No_Longer_Onboarding</template>
    </alerts>
    <fieldUpdates>
        <fullName>update_status_compliance_approved</fullName>
        <field>Job_Offer_Status__c</field>
        <literalValue>Compliance Approved - Pending Formal Offer</literalValue>
        <name>update status compliance approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update_status_submitted_for_approval</fullName>
        <field>Job_Offer_Status__c</field>
        <literalValue>Pending Compliance Approval</literalValue>
        <name>update status - submitted for approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
</Workflow>
