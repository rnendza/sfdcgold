<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Campaign_Notification_Amusements_Lead</fullName>
        <description>Campaign Notification: Amusements Lead</description>
        <protected>false</protected>
        <recipients>
            <field>Amusements_Lead__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Campaign_Notification_Amusements_Lead</template>
    </alerts>
    <alerts>
        <fullName>Campaign_Notification_Amusements_Support</fullName>
        <description>Campaign Notification: Amusements Support</description>
        <protected>false</protected>
        <recipients>
            <field>Amusements_Support__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Campaign_Notification_Amusements_Support</template>
    </alerts>
    <alerts>
        <fullName>Campaign_Notification_Machine_Lead</fullName>
        <description>Campaign Notification: Machine Lead</description>
        <protected>false</protected>
        <recipients>
            <field>Machine_Lead__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Campaign_Notification_Machine_Lead</template>
    </alerts>
    <alerts>
        <fullName>Campaign_Notification_Marketing_Lead</fullName>
        <description>Campaign Notification: Marketing Lead</description>
        <protected>false</protected>
        <recipients>
            <field>Marketing_Lead__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Campaign_Notification_Marketing_Lead</template>
    </alerts>
    <alerts>
        <fullName>Campaign_Notification_Marketing_Support</fullName>
        <description>Campaign Notification: Marketing Support</description>
        <protected>false</protected>
        <recipients>
            <field>Marketing_Support__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Campaign_Notification_Marketing_Support</template>
    </alerts>
    <alerts>
        <fullName>Campaign_Notification_Sales_Lead</fullName>
        <description>Campaign Notification: Sales Lead</description>
        <protected>false</protected>
        <recipients>
            <field>Sales_Lead__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Campaign_Notification_Sales_Lead</template>
    </alerts>
    <alerts>
        <fullName>Campaign_Notification_Sales_Support1</fullName>
        <description>Campaign Notification: Sales Support1</description>
        <protected>false</protected>
        <recipients>
            <field>Sales_Support_1__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Campaign_Notification_Sales_Support</template>
    </alerts>
    <alerts>
        <fullName>Campaign_Notification_Sales_Support2</fullName>
        <description>Campaign Notification: Sales Support2</description>
        <protected>false</protected>
        <recipients>
            <field>Sales_Support_2__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Campaign_Notification_Sales_Support</template>
    </alerts>
    <alerts>
        <fullName>Campaign_Notification_Sales_Support3</fullName>
        <description>Campaign Notification: Sales Support3</description>
        <protected>false</protected>
        <recipients>
            <field>Sales_Support_3__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Campaign_Notification_Sales_Support</template>
    </alerts>
    <alerts>
        <fullName>Campaign_Notification_Sales_Support4</fullName>
        <description>Campaign Notification: Sales Support4</description>
        <protected>false</protected>
        <recipients>
            <field>Sales_Support_4__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Campaign_Notification_Sales_Support</template>
    </alerts>
    <alerts>
        <fullName>Campaign_Notification_Technician_Lead</fullName>
        <description>Campaign Notification: Technician Lead</description>
        <protected>false</protected>
        <recipients>
            <field>Technician_Lead__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Campaign_Notification_Technician_Lead</template>
    </alerts>
    <alerts>
        <fullName>Campaign_Notification_Technician_Support</fullName>
        <description>Campaign Notification: Technician Support</description>
        <protected>false</protected>
        <recipients>
            <field>Technician_Support__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Campaign_Notification_Technician_Support</template>
    </alerts>
    <alerts>
        <fullName>Notify_Compliance_Approver</fullName>
        <description>Notify Compliance Approver</description>
        <protected>false</protected>
        <recipients>
            <recipient>Compliance</recipient>
            <type>role</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Compliance_Approval_Request</template>
    </alerts>
    <alerts>
        <fullName>Notify_Cost_Approver</fullName>
        <description>Notify Cost Approver</description>
        <protected>false</protected>
        <recipients>
            <recipient>Finance</recipient>
            <type>role</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Cost_Approval_Request</template>
    </alerts>
    <alerts>
        <fullName>Notify_Owner_Compliance_Responded</fullName>
        <description>Notify Owner Compliance Responded</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Compliance_Email_Response</template>
    </alerts>
    <alerts>
        <fullName>Notify_Owner_Cost_Responded</fullName>
        <description>Notify Owner Cost Responded</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Cost_Email_Response</template>
    </alerts>
    <fieldUpdates>
        <fullName>Update_Active_TRUE</fullName>
        <field>IsActive</field>
        <literalValue>1</literalValue>
        <name>Update Active = TRUE</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Date_Received_from_Event_Approve</fullName>
        <field>Date_Received_from_Event_Approver__c</field>
        <formula>TODAY()</formula>
        <name>Update “Date Received from Event Approve</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Date_Sent_to_Event_Approver</fullName>
        <field>Date_Sent_to_Event_Approver__c</field>
        <formula>TODAY()</formula>
        <name>Update &quot;Date Sent to Event Approver&quot;</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Status_Cancelled</fullName>
        <field>Status</field>
        <literalValue>Cancelled</literalValue>
        <name>Update Status = Cancelled</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Status_to_next_status</fullName>
        <field>Status</field>
        <name>Update &quot;Status&quot; to next status</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>NextValue</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
</Workflow>
