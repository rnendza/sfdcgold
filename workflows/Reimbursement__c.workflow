<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Accounting_Email_alert</fullName>
        <description>Accounting Email alert</description>
        <protected>false</protected>
        <recipients>
            <recipient>briseydag@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>chelsean@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>matthewa@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>vickyv@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Reimbursements/Alert_Accounting_Department</template>
    </alerts>
    <alerts>
        <fullName>COVID_Dividers_Reimbursement_Approval_Request</fullName>
        <description>COVID Location Expense Approval Request</description>
        <protected>false</protected>
        <recipients>
            <recipient>johnj@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Reimbursements/Request_for_Approval_COVID_Dividers</template>
    </alerts>
    <alerts>
        <fullName>COVID_Dividers_Reimbursement_Approval_Request_Compliance</fullName>
        <ccEmails>deepalim@accelentertainment.com</ccEmails>
        <description>COVID Location Expense Approval Request Compliance</description>
        <protected>false</protected>
        <recipients>
            <recipient>derekh@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Reimbursements/Request_for_Approval_COVID_Dividers</template>
    </alerts>
    <alerts>
        <fullName>Muni_Check_Request_Approved</fullName>
        <description>Muni Check Request Approved</description>
        <protected>false</protected>
        <recipients>
            <recipient>teresa.schoenhofen@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Muni_Check_Request_Approved</template>
    </alerts>
    <alerts>
        <fullName>Municipality_Check_Request</fullName>
        <ccEmails>LeslieS@accelentertainment.com</ccEmails>
        <ccEmails>KateV@accelentertainment.com</ccEmails>
        <ccEmails>ap2@accelentertainment.com</ccEmails>
        <description>Municipality Check Request</description>
        <protected>false</protected>
        <recipients>
            <recipient>briseydag@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>chelsean@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Reimbursements/Municipality_Check_Request</template>
    </alerts>
    <alerts>
        <fullName>Notification_Accounting_regarding_Reimbursement</fullName>
        <description>Notification Accounting regarding Reimbursement</description>
        <protected>false</protected>
        <recipients>
            <recipient>briseydag@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>chelsean@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>matthewa@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>vickyv@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Reimbursements/Alert_Accounting_Department</template>
    </alerts>
    <alerts>
        <fullName>Notification_regarding_Reimbursement</fullName>
        <description>Notification amusement regarding Reimbursement</description>
        <protected>false</protected>
        <recipients>
            <recipient>melissaq@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>tonys@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Reimbursements/Alert_Accounting_Department</template>
    </alerts>
    <alerts>
        <fullName>Notify_Compliance_of_the_buildout_request</fullName>
        <ccEmails>deepalim@accelentertainment.com</ccEmails>
        <description>Notify Compliance of New Buildout Request</description>
        <protected>false</protected>
        <recipients>
            <recipient>derekh@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Reimbursements/Reimbursement_Approvals_Request</template>
    </alerts>
    <alerts>
        <fullName>Notify_Compliance_of_the_request</fullName>
        <description>Notify Compliance of New Request</description>
        <protected>false</protected>
        <recipients>
            <recipient>alyssam@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>andream@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Reimbursements/Reimbursement_Approvals_Request</template>
    </alerts>
    <alerts>
        <fullName>Notify_Eric_of_Reimbursement_Submitted</fullName>
        <description>Notify Gaming of Reimbursement Submitted</description>
        <protected>false</protected>
        <recipients>
            <recipient>bruce.lamarca@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>johnj@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Reimbursements/Security_Reimbursement_Notification</template>
    </alerts>
    <alerts>
        <fullName>Notify_Finance_of_the_Reimbursement</fullName>
        <ccEmails>LeslieS@accelentertainment.com</ccEmails>
        <ccEmails>KateV@accelentertainment.com</ccEmails>
        <description>Notify Finance of the Reimbursement</description>
        <protected>false</protected>
        <recipients>
            <recipient>katev@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>leslies@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Reimbursements/Alert_Finance_Department</template>
    </alerts>
    <alerts>
        <fullName>Notify_Security_of_Reimbursement_Submitted</fullName>
        <description>Notify Security of Reimbursement Submitted</description>
        <protected>false</protected>
        <recipients>
            <recipient>jerryk@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Reimbursements/Security_Reimbursement_Notification</template>
    </alerts>
    <alerts>
        <fullName>Notify_submitter_of_Reimbursement_approval</fullName>
        <description>Notify submitter of Reimbursement approval</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Reimbursements/Reimbursement_Approval_Notification</template>
    </alerts>
    <alerts>
        <fullName>Reimbursement_Approved</fullName>
        <description>Reimbursement Approved</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Reimbursements/Reimbursement_Approved</template>
    </alerts>
    <alerts>
        <fullName>Reimbursement_Check_Issued</fullName>
        <description>Reimbursement Check Issued</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Reimbursements/Reimbursement_Check_Issued</template>
    </alerts>
    <alerts>
        <fullName>Reimbursement_Check_Issued_inactive_user</fullName>
        <description>Reimbursement Check Issued-inactive user</description>
        <protected>false</protected>
        <recipients>
            <recipient>daynam@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Reimbursements/Reimbursement_Check_Issued</template>
    </alerts>
    <alerts>
        <fullName>Reimbursement_is_put_on_hold</fullName>
        <description>Reimbursement is put on hold</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <recipients>
            <type>creator</type>
        </recipients>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Reimbursements/Reimbursement_on_hold_email_template</template>
    </alerts>
    <alerts>
        <fullName>Reimbursement_rejectedfinal</fullName>
        <description>Reimbursement Rejected</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <recipients>
            <type>creator</type>
        </recipients>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Reimbursement_rejectedfinal</template>
    </alerts>
    <alerts>
        <fullName>Request_Denied</fullName>
        <description>Request Denied</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <recipients>
            <type>creator</type>
        </recipients>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Reimbursement_rejectedfinal</template>
    </alerts>
    <alerts>
        <fullName>notify_finance_to_approve</fullName>
        <ccEmails>LeslieS@accelentertainment.com</ccEmails>
        <ccEmails>KateV@accelentertainment.com</ccEmails>
        <description>notify finance to approve</description>
        <protected>false</protected>
        <recipients>
            <recipient>katev@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>leslies@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Reimbursements/Alert_Finance_Department</template>
    </alerts>
    <fieldUpdates>
        <fullName>Approved_Reimbursement</fullName>
        <field>Status__c</field>
        <literalValue>Approved</literalValue>
        <name>Approved Reimbursement</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Approved_Status_Update</fullName>
        <field>Status__c</field>
        <literalValue>Approved</literalValue>
        <name>Approved Status Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Denied_Reimbursement</fullName>
        <field>Status__c</field>
        <literalValue>Denied</literalValue>
        <name>Denied Reimbursement</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Denied_Status_Update</fullName>
        <field>Status__c</field>
        <literalValue>Denied</literalValue>
        <name>Denied Status Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Final_approval_true</fullName>
        <field>Final_Approval_rcvd__c</field>
        <literalValue>1</literalValue>
        <name>Final approval= true</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>In_Amusement_Approval</fullName>
        <field>Status__c</field>
        <literalValue>In Amusement Approval</literalValue>
        <name>In Amusement Approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Mark_submitted_for_approval</fullName>
        <field>Submitted_for_Approval__c</field>
        <literalValue>1</literalValue>
        <name>Mark submitted for approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Sent_for_approval</fullName>
        <field>Submitted_for_Approval__c</field>
        <literalValue>1</literalValue>
        <name>Sent for approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Status_to_Compliance_Approval</fullName>
        <field>Status__c</field>
        <literalValue>In Compliance Approval</literalValue>
        <name>Update Status to Compliance Approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Status_to_Gaming_Approval</fullName>
        <field>Status__c</field>
        <literalValue>In Gaming Approval</literalValue>
        <name>Update Status to Gaming Approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Status_to_Pending</fullName>
        <field>Status__c</field>
        <literalValue>Requested</literalValue>
        <name>Update Status to Requested</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>NextValue</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Submitted_for_Approval</fullName>
        <field>Submitted_for_Approval__c</field>
        <literalValue>1</literalValue>
        <name>Update Submitted for Approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_status_to_Accounting_Approval</fullName>
        <field>Status__c</field>
        <literalValue>In Accounting Approval</literalValue>
        <name>Update status to Accounting Approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_status_to_approved</fullName>
        <description>update status of reimbursement to approved</description>
        <field>Status__c</field>
        <literalValue>Approved</literalValue>
        <name>Update status to approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_status_to_denied</fullName>
        <field>Status__c</field>
        <literalValue>Denied</literalValue>
        <name>Update status to denied</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>status_to_approved_pending_payment</fullName>
        <field>Status__c</field>
        <literalValue>Approved - Payment Pending</literalValue>
        <name>status to approved pending payment</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update_status_to_Security</fullName>
        <field>Status__c</field>
        <literalValue>In Security Approval</literalValue>
        <name>update status to Security</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
</Workflow>
