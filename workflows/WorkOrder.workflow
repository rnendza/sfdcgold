<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Send_to_Tech</fullName>
        <description>Send to Tech</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Service/Accel_Service_App</template>
    </alerts>
    <alerts>
        <fullName>Software_Needed_For_Appointment</fullName>
        <description>Software Needed For Appointment</description>
        <protected>false</protected>
        <recipients>
            <recipient>daynam@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>michaelp@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderAddress>crm@accelentertainment.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Service/Software_Needed_for_Appointment</template>
    </alerts>
</Workflow>
