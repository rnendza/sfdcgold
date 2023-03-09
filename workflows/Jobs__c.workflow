<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Company_credit_card_needed</fullName>
        <ccEmails>openreqs@accelentertainment.com</ccEmails>
        <description>Company credit card needed</description>
        <protected>false</protected>
        <recipients>
            <recipient>briseydag@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>katier@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Human_Resources/Company_credit_card_needed</template>
    </alerts>
    <alerts>
        <fullName>Job_Filled_Alert</fullName>
        <ccEmails>maxs@accelentertainment.com</ccEmails>
        <ccEmails>openreqs@accelentertainment.com</ccEmails>
        <description>Job Filled Alert</description>
        <protected>false</protected>
        <recipients>
            <recipient>kurtg@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>roys@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Human_Resources/Job_Filled</template>
    </alerts>
    <alerts>
        <fullName>Job_Requisition_Approved</fullName>
        <description>Job Requisition Approved</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <recipients>
            <recipient>jacquelinep@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>samanthaa@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <field>Executive_Approver__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Job_Requisition_Approved</template>
    </alerts>
    <alerts>
        <fullName>Job_Status_is_changed_to_Posted</fullName>
        <description>Job: Status is changed to Posted</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderAddress>crm@accelentertainment.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Human_Resources/Job_Status_changed_to_Posted</template>
    </alerts>
    <alerts>
        <fullName>Jobs_Notify_of_start_date_change</fullName>
        <ccEmails>maxs@accelentertainment.com</ccEmails>
        <description>Jobs: Notify of start date change</description>
        <protected>false</protected>
        <recipients>
            <recipient>daynam@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>kurtg@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Human_Resources/Jobs_Start_Date_Changed</template>
    </alerts>
    <alerts>
        <fullName>Jobs_Requisition_rejection_notification</fullName>
        <description>Jobs: Requisition rejection notification</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <recipients>
            <recipient>frankb@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Human_Resources/Requisition_Rejected</template>
    </alerts>
    <fieldUpdates>
        <fullName>HR_approval_checkbox_TRUE</fullName>
        <field>Human_Resources_Approval__c</field>
        <literalValue>1</literalValue>
        <name>HR approval checkbox TRUE</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>In_Budget_No</fullName>
        <field>In_Budget__c</field>
        <literalValue>No</literalValue>
        <name>In Budget No</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>In_Budget_Yes</fullName>
        <field>In_Budget__c</field>
        <literalValue>Yes</literalValue>
        <name>In Budget Yes</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Last_Candidate_Update</fullName>
        <description>update Last Candidate with the last value of Candidate Name (Accepted Offer)</description>
        <field>Last_Candidate_s_Name__c</field>
        <formula>PRIORVALUE( Candidate_Name__c )</formula>
        <name>Last Candidate Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Job_Status_to_Posted</fullName>
        <field>Job_Status__c</field>
        <literalValue>Posted</literalValue>
        <name>Update Job Status to &quot;Posted&quot;</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_job_status_to_in_approval</fullName>
        <field>Job_Status__c</field>
        <literalValue>In Approval</literalValue>
        <name>Update job status to in approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_record_type</fullName>
        <description>Update record type to &quot;Approved - Ready to Post&quot;</description>
        <field>RecordTypeId</field>
        <lookupValue>Job_Posting</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Update record type</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_record_type2</fullName>
        <field>RecordTypeId</field>
        <lookupValue>Job_Posting</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Update record type</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_requisition_approved_date</fullName>
        <field>Requisition_Approved_Date__c</field>
        <formula>TODAY()</formula>
        <name>Update requisition approved date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_status_to_approved</fullName>
        <field>Job_Status__c</field>
        <literalValue>Pending Posting</literalValue>
        <name>Update status to approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_submitted_date</fullName>
        <field>Submitted_Date__c</field>
        <formula>today()</formula>
        <name>Update submitted date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Job Filled Notification</fullName>
        <actions>
            <name>Job_Filled_Alert</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Jobs__c.Job_Status__c</field>
            <operation>equals</operation>
            <value>Filled</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Last Candidate</fullName>
        <actions>
            <name>Last_Candidate_Update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Jobs__c.Job_Status__c</field>
            <operation>equals</operation>
            <value>Posted</value>
        </criteriaItems>
        <description>update Last Candidate&apos;s Name field when job status is changed back to Posted because the Job Offer status was changed to No Longer Onboarding</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
