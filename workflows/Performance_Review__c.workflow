<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Send_an_email_notification_to_a_manager_when_a_review_has_been_completed</fullName>
        <description>Send an email notification to a manager when a review has been completed</description>
        <protected>false</protected>
        <recipients>
            <field>Manager__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Opportunity_Email_Templates/Performance_Review</template>
    </alerts>
    <alerts>
        <fullName>Send_an_email_notification_to_a_user_when_a_review_is_assigned_to_them</fullName>
        <description>Send an email notification to a user when a review is assigned to them</description>
        <protected>false</protected>
        <recipients>
            <field>Assigned_To__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Opportunity_Email_Templates/Assigned_Review</template>
    </alerts>
    <rules>
        <fullName>Assigned Review</fullName>
        <actions>
            <name>Send_an_email_notification_to_a_user_when_a_review_is_assigned_to_them</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Performance_Review__c.Assigned_To__c</field>
            <operation>notEqual</operation>
            <value>NULL</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Performance Review</fullName>
        <actions>
            <name>Send_an_email_notification_to_a_manager_when_a_review_has_been_completed</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Performance_Review__c.Status__c</field>
            <operation>equals</operation>
            <value>Completed</value>
        </criteriaItems>
        <criteriaItems>
            <field>User.ManagerId</field>
            <operation>notEqual</operation>
            <value>NULL</value>
        </criteriaItems>
        <description>Send an email notificaitno to a manager when a review has been completed</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
