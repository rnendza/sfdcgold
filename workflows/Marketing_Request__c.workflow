<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>AEPlayer_TV_Approved</fullName>
        <description>AEPlayer TV Approved</description>
        <protected>false</protected>
        <recipients>
            <field>Assigned_Marketing_Coordinator__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/AE_TV_Player_Approved_to_Marketing_Coordinator</template>
    </alerts>
    <alerts>
        <fullName>Admin_Alert</fullName>
        <description>Admin Alert</description>
        <protected>false</protected>
        <recipients>
            <recipient>salesforce@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Standard_Approval</template>
    </alerts>
    <alerts>
        <fullName>Alert_Accounting</fullName>
        <description>Alert Accounting</description>
        <protected>false</protected>
        <recipients>
            <recipient>Accounting</recipient>
            <type>group</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Alert_Accounting</template>
    </alerts>
    <alerts>
        <fullName>Alert_when_cost_split_is_not_listed</fullName>
        <description>Alert when cost split is not listed</description>
        <protected>false</protected>
        <recipients>
            <field>Assigned_Marketing_Coordinator__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Split_cost_no_cost_share_info</template>
    </alerts>
    <alerts>
        <fullName>Approval_Rejected</fullName>
        <description>Approval Rejected</description>
        <protected>false</protected>
        <recipients>
            <field>Assigned_Marketing_Coordinator__c</field>
            <type>userLookup</type>
        </recipients>
        <recipients>
            <field>FSG_User_Lookup__c</field>
            <type>userLookup</type>
        </recipients>
        <recipients>
            <field>Name_of_Person_Requesting__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Standard_Rejection</template>
    </alerts>
    <alerts>
        <fullName>Approved_Email_Text</fullName>
        <description>Approved: Email/Text</description>
        <protected>false</protected>
        <recipients>
            <field>Assigned_Marketing_Coordinator__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Approval_Received_Email_Text</template>
    </alerts>
    <alerts>
        <fullName>Art_Approval_Needed</fullName>
        <description>Art Approval Needed</description>
        <protected>false</protected>
        <recipients>
            <field>Art_Approver__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Art_Approval_Needed</template>
    </alerts>
    <alerts>
        <fullName>Art_Approval_Received</fullName>
        <description>Art Approval Received</description>
        <protected>false</protected>
        <recipients>
            <field>Assigned_Marketing_Coordinator__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Art_Approval_Received</template>
    </alerts>
    <alerts>
        <fullName>Brand_Ambassador_Event_Approved</fullName>
        <description>Brand Ambassador Event Approved</description>
        <protected>false</protected>
        <recipients>
            <field>Assigned_Marketing_Coordinator__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Brand_Ambassador_Event_Approved</template>
    </alerts>
    <alerts>
        <fullName>Brand_Ambassador_Rejection</fullName>
        <description>Brand Ambassador Rejection</description>
        <protected>false</protected>
        <recipients>
            <field>Assigned_Marketing_Coordinator__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Brand_Ambassador_Event_Rejection</template>
    </alerts>
    <alerts>
        <fullName>Compliance_Promo_Denied</fullName>
        <description>Compliance Promo Denied</description>
        <protected>false</protected>
        <recipients>
            <field>Assigned_Marketing_Coordinator__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Promotion_Request_Denied</template>
    </alerts>
    <alerts>
        <fullName>Content_Coordinator_Notification</fullName>
        <description>Content Coordinator Notification</description>
        <protected>false</protected>
        <recipients>
            <field>Content_Coordinator__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Notify_Content_Coordinator</template>
    </alerts>
    <alerts>
        <fullName>Email_requestor_when_all_co_op_approvals_received</fullName>
        <description>Email requestor when all co-op approvals received</description>
        <protected>false</protected>
        <recipients>
            <field>Name_of_Person_Requesting__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Co_Op_All_Approvals_Received</template>
    </alerts>
    <alerts>
        <fullName>Event_Items_Ready_for_Pickup</fullName>
        <description>Event Items Ready for Pickup</description>
        <protected>false</protected>
        <recipients>
            <field>AdditionalBrandAmbassador__c</field>
            <type>contactLookup</type>
        </recipients>
        <recipients>
            <field>Brand_Ambassador__c</field>
            <type>contactLookup</type>
        </recipients>
        <recipients>
            <recipient>emilyk@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Event_Items_Ready_for_Pickup</template>
    </alerts>
    <alerts>
        <fullName>Excess_Reimbursement_paid</fullName>
        <description>Excess Reimbursement paid</description>
        <protected>false</protected>
        <recipients>
            <recipient>amberw@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>daynam@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <field>Assigned_Marketing_Coordinator__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Excess_Reimbursement_Amount</template>
    </alerts>
    <alerts>
        <fullName>Folds_of_Honor_Accounting_Approval_Request</fullName>
        <description>Folds of Honor Accounting Approval Request</description>
        <protected>false</protected>
        <recipients>
            <recipient>chelsean@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Folds_of_Honor</template>
    </alerts>
    <alerts>
        <fullName>Folds_of_Honor_Approved</fullName>
        <description>Folds of Honor Approved</description>
        <protected>false</protected>
        <recipients>
            <field>FSG_User_Lookup__c</field>
            <type>userLookup</type>
        </recipients>
        <recipients>
            <field>Name_of_Person_Requesting__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Folds_of_Honor_Approved</template>
    </alerts>
    <alerts>
        <fullName>Folds_of_Honor_Initial_Approval_Request</fullName>
        <description>Folds of Honor Initial Approval Request</description>
        <protected>false</protected>
        <recipients>
            <recipient>amberw@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Folds_of_Honor</template>
    </alerts>
    <alerts>
        <fullName>Folds_of_Honor_denied</fullName>
        <description>Folds of Honor denied</description>
        <protected>false</protected>
        <recipients>
            <field>FSG_User_Lookup__c</field>
            <type>userLookup</type>
        </recipients>
        <recipients>
            <field>Name_of_Person_Requesting__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Folds_of_Honor_Denied</template>
    </alerts>
    <alerts>
        <fullName>Install_Required_Item_Received</fullName>
        <description>Install Required - Item Received</description>
        <protected>false</protected>
        <recipients>
            <recipient>amberw@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Install_Required_Item_Ready</template>
    </alerts>
    <alerts>
        <fullName>Installation_Required</fullName>
        <description>Installation Required</description>
        <protected>false</protected>
        <recipients>
            <recipient>amberw@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Installation_Required</template>
    </alerts>
    <alerts>
        <fullName>Installation_Scheduled</fullName>
        <description>Installation Scheduled</description>
        <protected>false</protected>
        <recipients>
            <field>FSG_User_Lookup__c</field>
            <type>userLookup</type>
        </recipients>
        <recipients>
            <field>Name_of_Person_Requesting__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Custom_Installation_Schedule</template>
    </alerts>
    <alerts>
        <fullName>MC_Compliance_Approval_Alert</fullName>
        <description>MC Compliance Approval Alert</description>
        <protected>false</protected>
        <recipients>
            <field>Assigned_Marketing_Coordinator__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Notify_MC_of_compliance_approval</template>
    </alerts>
    <alerts>
        <fullName>MC_Cost_approval_alert</fullName>
        <description>MC Cost approval alert</description>
        <protected>false</protected>
        <recipients>
            <field>Assigned_Marketing_Coordinator__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Notify_MC_that_cost_approvals_Received</template>
    </alerts>
    <alerts>
        <fullName>Marketing_Request_MC</fullName>
        <description>Marketing Request MC</description>
        <protected>false</protected>
        <recipients>
            <field>Assigned_Marketing_Coordinator__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/MC_Assigned_Co_Op</template>
    </alerts>
    <alerts>
        <fullName>Marketing_item_is_ready_to_order</fullName>
        <description>Marketing item is ready to order</description>
        <protected>false</protected>
        <recipients>
            <field>Assigned_Marketing_Coordinator__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Item_Ready_to_Order</template>
    </alerts>
    <alerts>
        <fullName>Marketing_notify_ops_mgr_of_request_for_measurements</fullName>
        <description>Marketing: notify ops mgr of request for measurements</description>
        <protected>false</protected>
        <recipients>
            <recipient>kriss@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>taniag@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Request_for_Measurements</template>
    </alerts>
    <alerts>
        <fullName>Marketing_notify_requestor_when_paid</fullName>
        <ccEmails>daynam@accelentertainment.com</ccEmails>
        <description>Marketing: notify requestor when paid</description>
        <protected>false</protected>
        <recipients>
            <field>FSG_User_Lookup__c</field>
            <type>userLookup</type>
        </recipients>
        <recipients>
            <field>Name_of_Person_Requesting__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Marketing_request_paid</template>
    </alerts>
    <alerts>
        <fullName>Million_Dollar_Approval_Alert</fullName>
        <description>Million Dollar Approval Alert</description>
        <protected>false</protected>
        <recipients>
            <field>Name_of_Person_Requesting__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Million_Dollar_Giveaway_Approval</template>
    </alerts>
    <alerts>
        <fullName>New_Digital_Marketing_Request</fullName>
        <ccEmails>hello@accelentertainment.com</ccEmails>
        <description>New Digital Marketing Request</description>
        <protected>false</protected>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/New_Digital_Marketing_Request</template>
    </alerts>
    <alerts>
        <fullName>New_Marketing_Request_Received</fullName>
        <description>New Marketing Request Received</description>
        <protected>false</protected>
        <recipients>
            <recipient>amberw@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/New_Marketing_Request</template>
    </alerts>
    <alerts>
        <fullName>New_Promo_Marketing_Request</fullName>
        <description>New Promo Marketing Request</description>
        <protected>false</protected>
        <recipients>
            <recipient>amberw@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Compliance_Approval_Request</template>
    </alerts>
    <alerts>
        <fullName>New_Promo_Marketing_Request_2</fullName>
        <description>New Promo Marketing Request</description>
        <protected>false</protected>
        <recipients>
            <recipient>amberw@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/New_Promo_Marketing_Request</template>
    </alerts>
    <alerts>
        <fullName>Non_standard_item_ready_for_pickup</fullName>
        <description>Non-standard item ready for pickup</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <recipients>
            <field>FSG_User_Lookup__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Non_standard_request_ready_for_pickup</template>
    </alerts>
    <alerts>
        <fullName>Notify_Amber_Out_of_Budget_Approved</fullName>
        <description>Notify Amber Out of Budget Approved</description>
        <protected>false</protected>
        <recipients>
            <recipient>amberw@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/New_Promo_Marketing_Request</template>
    </alerts>
    <alerts>
        <fullName>Notify_MC_when_invoice_uploaded</fullName>
        <description>Notify MC when invoice uploaded</description>
        <protected>false</protected>
        <recipients>
            <field>Assigned_Marketing_Coordinator__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Invoice_Submitted</template>
    </alerts>
    <alerts>
        <fullName>Notify_Marketing_Coordinator_Promo_Request</fullName>
        <description>Notify Marketing Coordinator Promo Request</description>
        <protected>false</protected>
        <recipients>
            <field>Assigned_Marketing_Coordinator__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Promo_Request_Marketing_Coordinator</template>
    </alerts>
    <alerts>
        <fullName>Notify_marketing_that_an_invoice_has_been_uploaded</fullName>
        <description>Notify marketing that an invoice has been uploaded</description>
        <protected>false</protected>
        <recipients>
            <field>Assigned_Marketing_Coordinator__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Alert_Marketing_that_Invoice_is_Uploaded</template>
    </alerts>
    <alerts>
        <fullName>Notify_requestor_that_they_may_add_the_cash_promo_to_the_tablet</fullName>
        <description>Notify requestor that they may add the cash promo to the tablet</description>
        <protected>false</protected>
        <recipients>
            <field>Name_of_Person_Requesting__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Sweepstakes_Promotion_Approved</template>
    </alerts>
    <alerts>
        <fullName>Order_Placed</fullName>
        <description>Order Placed</description>
        <protected>false</protected>
        <recipients>
            <field>FSG_User_Lookup__c</field>
            <type>userLookup</type>
        </recipients>
        <recipients>
            <field>Name_of_Person_Requesting__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Order_Placed</template>
    </alerts>
    <alerts>
        <fullName>Post_Event_Data_Reminder</fullName>
        <description>Post-Event Data Reminder</description>
        <protected>false</protected>
        <recipients>
            <field>Assigned_Marketing_Coordinator__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Post_Event_Reminder</template>
    </alerts>
    <alerts>
        <fullName>Pre_Event_Data_Collection</fullName>
        <description>Pre Event Data Collection</description>
        <protected>false</protected>
        <recipients>
            <field>Assigned_Marketing_Coordinator__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Pre_Event_Data_Collection_Reminder</template>
    </alerts>
    <alerts>
        <fullName>Promo_Completion</fullName>
        <description>Promo Completion</description>
        <protected>false</protected>
        <recipients>
            <field>Assigned_Marketing_Coordinator__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Promo_Complete</template>
    </alerts>
    <alerts>
        <fullName>Promo_Cost_Approved</fullName>
        <description>Promo Cost Approved</description>
        <protected>false</protected>
        <recipients>
            <field>Assigned_Marketing_Coordinator__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Promo_Cost_Approved</template>
    </alerts>
    <alerts>
        <fullName>Promo_Cost_Rejected</fullName>
        <description>Promo Cost Rejected</description>
        <protected>false</protected>
        <recipients>
            <field>Assigned_Marketing_Coordinator__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Promo_Cost_Rejected</template>
    </alerts>
    <alerts>
        <fullName>Request_for_email_text_approval</fullName>
        <description>Request for email text approval</description>
        <protected>false</protected>
        <recipients>
            <field>Email_Text_Approver__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Approval_Needed_Email_Text</template>
    </alerts>
    <alerts>
        <fullName>Request_for_social_media_approval</fullName>
        <description>Request for social media approval</description>
        <protected>false</protected>
        <recipients>
            <field>Social_Media_Approver__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Social_Media_Approval_Needed</template>
    </alerts>
    <alerts>
        <fullName>Send_Email_to_Finance_AE_TV_Opt_Out</fullName>
        <description>Send Email to Finance AE TV Opt Out</description>
        <protected>false</protected>
        <recipients>
            <recipient>briseydag@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>chelsean@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderAddress>crm@accelentertainment.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/AE_TV_Player_Opt_Out</template>
    </alerts>
    <alerts>
        <fullName>Social_Media_Approved</fullName>
        <description>Social Media Approved</description>
        <protected>false</protected>
        <recipients>
            <field>Assigned_Marketing_Coordinator__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Social_Media_Approval_Received</template>
    </alerts>
    <alerts>
        <fullName>Standard_Approval</fullName>
        <description>Standard Approval</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Standard_Approval</template>
    </alerts>
    <alerts>
        <fullName>Standard_Approval_Digital</fullName>
        <description>Standard Approval - Digital</description>
        <protected>false</protected>
        <recipients>
            <field>Assigned_Marketing_Coordinator__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Standard_Approval</template>
    </alerts>
    <alerts>
        <fullName>Standard_Custom_Size_Approval</fullName>
        <description>Standard Custom Size Approval</description>
        <protected>false</protected>
        <recipients>
            <field>Assigned_Marketing_Coordinator__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Standard_Custom_Size_Compliance_Approval</template>
    </alerts>
    <alerts>
        <fullName>Standard_Rejected</fullName>
        <description>Standard Rejected</description>
        <protected>false</protected>
        <recipients>
            <field>Assigned_Marketing_Coordinator__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Standard_Rejection</template>
    </alerts>
    <alerts>
        <fullName>Sweepstakes_Promotion_approved</fullName>
        <description>Sweepstakes Promotion approved</description>
        <protected>false</protected>
        <recipients>
            <field>Name_of_Person_Requesting__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Sweepstakes_Promotion_Approved</template>
    </alerts>
    <alerts>
        <fullName>Sweepstakes_approval</fullName>
        <description>Sweepstakes approval</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Sweepstakes_Approved</template>
    </alerts>
    <alerts>
        <fullName>Sweepstakes_approved</fullName>
        <description>Sweepstakes approved</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <recipients>
            <field>FSG_User_Lookup__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Sweepstakes_Approved</template>
    </alerts>
    <alerts>
        <fullName>TouchTunes_Content_Complete</fullName>
        <description>TouchTunes Content Complete</description>
        <protected>false</protected>
        <recipients>
            <field>Assigned_Marketing_Coordinator__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/TouchTunes_Content_Completed</template>
    </alerts>
    <alerts>
        <fullName>Warehouse_completed_touch_tunes_item</fullName>
        <description>Warehouse completed touch tunes item</description>
        <protected>false</protected>
        <recipients>
            <recipient>mirandaj@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Touch_Tunes_warehouse_items_filled</template>
    </alerts>
    <alerts>
        <fullName>marketing_notify_marketing_when_initial_promo_is_approved_by_compliance</fullName>
        <description>marketing: notify marketing when initial promo is approved by compliance</description>
        <protected>false</protected>
        <recipients>
            <field>Assigned_Marketing_Coordinator__c</field>
            <type>userLookup</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Marketing_Email_Templates/Promo_Compliance_approval</template>
    </alerts>
    <fieldUpdates>
        <fullName>Art_Approval_Date_Rcvd</fullName>
        <field>Date_of_Art_Approval__c</field>
        <formula>today()</formula>
        <name>Art Approval Date Rcvd</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Cost_denied</fullName>
        <field>Cost_Approval__c</field>
        <literalValue>Cost Rejected</literalValue>
        <name>Cost denied</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Cost_rejected</fullName>
        <field>Cost_Approval__c</field>
        <literalValue>Cost Rejected</literalValue>
        <name>Cost denied</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Date_Accounting_Approves_Opt_Out</fullName>
        <field>Date_Accounting_Approves_Opt_Out__c</field>
        <formula>TODAY()</formula>
        <name>Date Accounting Approves Opt Out</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Date_Accounting_approval_rcvd</fullName>
        <field>Date_Accounting_Approval_Rcvd__c</field>
        <formula>today()</formula>
        <name>Date Accounting approval rcvd</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Date_Compliance_Approval_Rcd</fullName>
        <field>Date_Compliance_Approval_Rcvd__c</field>
        <formula>TODAY()</formula>
        <name>Date Compliance Approval Rcd</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Date_Email_Text_Approved</fullName>
        <field>Date_Email_Text_Approved__c</field>
        <formula>today()</formula>
        <name>Date Email Text Approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Date_Regional_Approval_Rcvd</fullName>
        <field>Date_Regional_Lead_Approval_Received__c</field>
        <formula>today()</formula>
        <name>Date Regional Approval Rcvd</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Date_Sent_For_Cost_Approval</fullName>
        <field>Date_Sent_For_Cost_Approval__c</field>
        <formula>TODAY()</formula>
        <name>Date Sent For Cost Approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Date_Sent_for_Regional_Approval</fullName>
        <field>Date_Sent_for_Regional_Lead_Approval__c</field>
        <formula>today()</formula>
        <name>Date Sent for Regional Approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Date_Sent_for_marketing_approval</fullName>
        <field>Date_Sent_for_Marketing_Manager_Approval__c</field>
        <formula>today()</formula>
        <name>Date Sent for marketing approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Date_marketing_approval_rcvd</fullName>
        <field>Date_Marketing_Manager_Approval_Rcvd__c</field>
        <formula>today()</formula>
        <name>Date marketing approval rcvd</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Date_sent_for_compliance_approval</fullName>
        <field>Date_Sent_For_Compliance_Approval__c</field>
        <formula>today()</formula>
        <name>Date sent for compliance approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Date_sent_to_accounting</fullName>
        <field>Date_Sent_to_Accounting__c</field>
        <formula>today()</formula>
        <name>Date sent to accounting</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Dayna_cost_approved</fullName>
        <field>Cost_Approval__c</field>
        <literalValue>Cost Approved</literalValue>
        <name>Dayna cost approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Finance_Approval_Uncheck</fullName>
        <field>Finance_Approval_Submission__c</field>
        <literalValue>0</literalValue>
        <name>Finance Approval Uncheck</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Mark_status_as_rejected</fullName>
        <field>Marketing_Project_Status__c</field>
        <literalValue>Rejected</literalValue>
        <name>Mark status as rejected</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Product_Stage_Equipment_Setup</fullName>
        <field>Project_Stage__c</field>
        <literalValue>Equipment Setup</literalValue>
        <name>Product Stage Equipment Setup</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Project_Stage_Approval</fullName>
        <field>Project_Stage__c</field>
        <literalValue>Approval</literalValue>
        <name>Project Stage = Approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Project_Stage_Opt_Out</fullName>
        <field>Project_Stage__c</field>
        <literalValue>Opt-Out</literalValue>
        <name>Project Stage Opt Out</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Stage_to_approved_pending_payment</fullName>
        <field>Project_Stage__c</field>
        <literalValue>Approved - Payment Pending</literalValue>
        <name>Stage to approved pending payment</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Status_to_Accounting</fullName>
        <field>Project_Stage__c</field>
        <literalValue>Accounting</literalValue>
        <name>Status to Accounting</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Status_to_Approved_Pending_Payment</fullName>
        <field>Marketing_Project_Status__c</field>
        <literalValue>Approved - Payment Pending</literalValue>
        <name>Status to Approved Pending Payment</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Cost_Approval_Date</fullName>
        <field>Date_Cost_Approval_Received__c</field>
        <formula>TODAY()</formula>
        <name>Update Cost Approval Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Date_Cost_Approval_Rcvd</fullName>
        <field>Date_Cost_Approval_Received__c</field>
        <formula>today()</formula>
        <name>Update Date Cost Approval Rcvd</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Date_Mktg_Mgr_Approved</fullName>
        <field>Date_Marketing_Manager_Approval_Rcvd__c</field>
        <formula>today()</formula>
        <name>Update Date Mktg Mgr Approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Date_Sent_For_Compliance_Approval</fullName>
        <field>Date_Sent_For_Compliance_Approval__c</field>
        <formula>TODAY()</formula>
        <name>Update Date Sent For Compliance Approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Date_Sent_for_Cost_Approval</fullName>
        <field>Date_Sent_For_Cost_Approval__c</field>
        <formula>today()</formula>
        <name>Update Date Sent for Cost Approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Date_Sent_for_Email_Text_Approval</fullName>
        <field>Date_Sent_for_Email_Text_Approval__c</field>
        <formula>today()</formula>
        <name>Update Date Sent for Email Text Approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Standard_Path</fullName>
        <description>update the standard path to indicate it is now at Approvals.</description>
        <field>Standard_Items_Path__c</field>
        <literalValue>Approvals</literalValue>
        <name>Update Standard Path</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_date_sent_for_art_approval</fullName>
        <field>Date_Sent_for_Art_Approval__c</field>
        <formula>today()</formula>
        <name>Update date sent for art approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_generic_mktg_stage_to</fullName>
        <field>Marketing_Project_Status__c</field>
        <literalValue>In Approval</literalValue>
        <name>Update generic mktg stage to</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_project_stage</fullName>
        <field>Project_Stage__c</field>
        <literalValue>Complete (Vendor Invoice Pending)</literalValue>
        <name>Update project stage</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_standard_product</fullName>
        <field>Standard_Product__c</field>
        <literalValue>1</literalValue>
        <name>Update standard product</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_status_to_in_approval</fullName>
        <field>Marketing_Project_Status__c</field>
        <literalValue>In Approval</literalValue>
        <name>Update status to in approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>cost_approved</fullName>
        <field>Cost_Approval__c</field>
        <literalValue>Cost Approved</literalValue>
        <name>cost approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>date_accounting_approvals_opt_out</fullName>
        <field>Date_Accounting_Approves_Opt_Out__c</field>
        <formula>today()</formula>
        <name>date accounting approvals opt out</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>date_compliance_app_rvcd</fullName>
        <field>Date_Compliance_Approval_Rcvd__c</field>
        <formula>today()</formula>
        <name>date compliance app rvcd</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>date_submit_opt_out_to_acctg</fullName>
        <field>Date_Submit_Opt_Out_to_Accounting__c</field>
        <formula>today()</formula>
        <name>date submit opt out to acctg</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>marketing_proj_status_to_accounting</fullName>
        <field>Marketing_Project_Status__c</field>
        <literalValue>Pending with Accounting</literalValue>
        <name>marketing proj status to accounting</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>pending_cost_approval</fullName>
        <field>Cost_Approval__c</field>
        <literalValue>Pending</literalValue>
        <name>pending cost approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update_all_approvals_received</fullName>
        <field>Approvals_Complete__c</field>
        <literalValue>1</literalValue>
        <name>update all approvals received</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update_approvals_complete_checkbox</fullName>
        <field>Approvals_Complete__c</field>
        <literalValue>1</literalValue>
        <name>update approvals complete checkbox</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update_date_cost_share_sent</fullName>
        <field>Cost_Share_Sent_To_Accounting__c</field>
        <formula>today()</formula>
        <name>update date cost share sent</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update_date_sent_to_accounting</fullName>
        <field>Date_Sent_to_Accounting__c</field>
        <formula>today()</formula>
        <name>update date sent to accounting</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update_generic_marketing_stage</fullName>
        <field>Marketing_Project_Status__c</field>
        <literalValue>Submitted to Warehouse</literalValue>
        <name>update generic marketing stage</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update_marketing_proj_status_pendinginv</fullName>
        <field>Marketing_Project_Status__c</field>
        <literalValue>Pending Promotion Invoices</literalValue>
        <name>update marketing proj status pending inv</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update_mktg_project_status_to_opt_out</fullName>
        <field>Marketing_Project_Status__c</field>
        <literalValue>Opt Out</literalValue>
        <name>update mktg project status to opt out</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update_project_completed_date</fullName>
        <field>Project_Completed_Date__c</field>
        <formula>today()</formula>
        <name>update project completed date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update_project_stage_to_approval</fullName>
        <field>Project_Stage__c</field>
        <literalValue>Approval</literalValue>
        <name>update project stage to approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update_project_stage_to_opt_out</fullName>
        <field>Project_Stage__c</field>
        <literalValue>Opt-Out</literalValue>
        <name>update project stage to opt out</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update_stage_to</fullName>
        <field>Project_Stage__c</field>
        <literalValue>Project Completion</literalValue>
        <name>update stage to complete</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>update_standard_path2</fullName>
        <field>Standard_Items_Path__c</field>
        <literalValue>Request Sent To Warehouse</literalValue>
        <name>update standard path2</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
</Workflow>
