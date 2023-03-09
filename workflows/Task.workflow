<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Leadership_review_GA_completed</fullName>
        <description>Leadership review GA completed</description>
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
        <template>unfiled$public/Opportunity_Leadership_Review_Completed</template>
    </alerts>
    <alerts>
        <fullName>Marketing_Task_Completion_Alert</fullName>
        <description>Marketing Task Completion Alert</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Marketing_Notify_of_Task_Completion</template>
    </alerts>
    <alerts>
        <fullName>Opportunity_Task_Leadership_Approval_Completed</fullName>
        <description>Opportunity Task Leadership Approval Completed</description>
        <protected>false</protected>
        <recipients>
            <recipient>pennys@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Opportunity_Leadership_Review_Completed</template>
    </alerts>
    <alerts>
        <fullName>Opportunity_notify_of_task_completion_Machine_Assignment</fullName>
        <description>Opportunity notify of task completion: Machine Assignment</description>
        <protected>false</protected>
        <recipients>
            <recipient>margaretg@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>shanei@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Opportunity_Task_Completion_Machine_Assignment</template>
    </alerts>
    <alerts>
        <fullName>Task_Notify_Creator_of_Task_Completion</fullName>
        <description>Task: Notify Creator of Task Completion</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <senderAddress>crm@accelentertainment.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/Notify_Task_Creator_of_Task_Completion</template>
    </alerts>
    <alerts>
        <fullName>Task_Notify_Sales_Ops_of_Task_Completion</fullName>
        <description>Task: Notify Sales Ops of Task Completion</description>
        <protected>false</protected>
        <recipients>
            <recipient>shanei@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderAddress>crm@accelentertainment.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/Notify_Sales_Ops_of_Task_Completion</template>
    </alerts>
</Workflow>
