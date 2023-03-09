<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>A_new_project_has_been_created</fullName>
        <description>A new project has been created</description>
        <protected>false</protected>
        <recipients>
            <recipient>jennifers@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>samanthaw@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Project/New_Project_Notification</template>
    </alerts>
    <alerts>
        <fullName>Add_Scheduled_Go_Live_date</fullName>
        <description>Add: Scheduled Go Live date</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Project/Add_Scheduled_Go_Live_Date_Notification</template>
    </alerts>
    <alerts>
        <fullName>Add_Scheduled_Install_Date</fullName>
        <description>Add: Scheduled Install Date</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Project/Add_Scheduled_Install_Date_Notification</template>
    </alerts>
    <alerts>
        <fullName>Add_Swap_Reconfigure_Field_Assessment_Needed</fullName>
        <description>Add/Swap/Reconfigure Field Assessment Needed</description>
        <protected>false</protected>
        <recipients>
            <recipient>davew@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>johnj@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Project/Add_Swap_Reconfig_Field_Assessment_Needed</template>
    </alerts>
    <alerts>
        <fullName>Add_Swap_Reconfigure_Project_Creation</fullName>
        <description>Add/Swap/Reconfigure Project Creation</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Project/Add_Swap_Reconfig_Project_Creation</template>
    </alerts>
    <alerts>
        <fullName>Gaming_Assets_Delivered</fullName>
        <description>Gaming Assets Delivered</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Gaming_Assets_Delivered</template>
    </alerts>
    <alerts>
        <fullName>Install_Approved_and_Compliance_Fields_have_been_activated</fullName>
        <description>Install Approved and Compliance Fields have been activated</description>
        <protected>false</protected>
        <recipients>
            <recipient>anthonyc@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>marieb@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>paule@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Service/Compliance_Fields_Yes</template>
    </alerts>
    <alerts>
        <fullName>Notify_PM_to_Complete_Buildout_Info_for_Won_Organic_Opp</fullName>
        <description>Notify PM to Complete Buildout Info for Won Organic Opp</description>
        <protected>false</protected>
        <recipients>
            <recipient>jennifers@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>samanthaw@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderAddress>crm@accelentertainment.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Project/Project_Buildout_Notification_to_PM</template>
    </alerts>
    <alerts>
        <fullName>Proj_Gaming_Area_Assets_rejection</fullName>
        <description>Proj Gaming Area Assets rejection</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Proj_Gaming_Assets_Rejection</template>
    </alerts>
    <alerts>
        <fullName>Project_Approval_Sales_Ops</fullName>
        <description>Project Approval: Sales Ops: Organic</description>
        <protected>false</protected>
        <recipients>
            <recipient>jennifers@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>pennys@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>samanthaw@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Project/Project_Approval_Sales_Ops</template>
    </alerts>
    <alerts>
        <fullName>Project_Approval_Sales_Ops_Competitor</fullName>
        <description>Project Approval: Sales Ops: Competitor</description>
        <protected>false</protected>
        <recipients>
            <recipient>jennifers@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>samanthaw@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Project/Project_Approval_Sales_Ops</template>
    </alerts>
    <alerts>
        <fullName>Project_Approved_Notification_to_Owner</fullName>
        <description>Project Approved Notification to Owner</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Project/Project_Approved_Notification</template>
    </alerts>
    <alerts>
        <fullName>Project_Gaming_Area_Assets_Rejection</fullName>
        <description>Project Gaming Area Assets Rejection</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Project_Gaming_Area_Assets_Rejection</template>
    </alerts>
    <alerts>
        <fullName>Project_Initial_Machine_Change</fullName>
        <description>Project Initial Machine Request</description>
        <protected>false</protected>
        <recipients>
            <recipient>nickv@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>qinlinl@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Project/Project_Initial_Machine_Request</template>
    </alerts>
    <alerts>
        <fullName>Project_Request_machine_change</fullName>
        <description>Project Request machine change</description>
        <protected>false</protected>
        <recipients>
            <recipient>marieb@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>nickv@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>qinlinl@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Project/Project_Request_Machine_Change</template>
    </alerts>
    <alerts>
        <fullName>Project_notify_of_asset_allocation</fullName>
        <description>Project: notify of asset allocation</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Project/Project_notify_of_asset_allocation</template>
    </alerts>
    <alerts>
        <fullName>Scheduled_Go_Live_Date_Notification</fullName>
        <description>Scheduled Go Live Date Notification</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <recipients>
            <type>owner</type>
        </recipients>
        <recipients>
            <recipient>daynam@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Project/Scheduled_Go_Live_Date_Notification</template>
    </alerts>
    <alerts>
        <fullName>Scheduled_Install_Date_Notification</fullName>
        <description>Scheduled Install Date Notification</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <recipients>
            <type>owner</type>
        </recipients>
        <recipients>
            <recipient>daynam@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Project/Scheduled_Install_Date_Notification</template>
    </alerts>
    <alerts>
        <fullName>Send_Asset_Located_Email</fullName>
        <description>Send Asset Located Email</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <recipients>
            <recipient>Regional_Manager</recipient>
            <type>role</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Project/Project_Owner</template>
    </alerts>
    <alerts>
        <fullName>Send_Notification_of_Approval</fullName>
        <description>Send Notification of Approval</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Project_Step_was_Approved</template>
    </alerts>
    <alerts>
        <fullName>Send_Notification_of_Rejection</fullName>
        <description>Send Notification of Rejection</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Project_Was_Rejected</template>
    </alerts>
    <alerts>
        <fullName>Update_Compliance</fullName>
        <description>Update Compliance if 1 week before Go-Live and not approved</description>
        <protected>false</protected>
        <recipients>
            <recipient>alyssam@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>marieb@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Service/Go_Live_Not_Approved</template>
    </alerts>
    <alerts>
        <fullName>Update_Compliance_if_1_week_before_Go_Live_and_not_approved</fullName>
        <description>Update Compliance if 1 week before Go-Live and not approved</description>
        <protected>false</protected>
        <recipients>
            <recipient>alyssam@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>marieb@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Service/Go_Live_Not_Approved</template>
    </alerts>
    <alerts>
        <fullName>When_Install_Approved_is_Yes_alert_parts_depts</fullName>
        <description>When &quot;Install Approved&quot; is Yes - alert parts depts</description>
        <protected>false</protected>
        <recipients>
            <recipient>Parts_Department</recipient>
            <type>role</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Service/Parts_Department</template>
    </alerts>
    <alerts>
        <fullName>When_VGT_information_needed_is_checked_we_need_to_alert_Marie_Both_Organic_and_C</fullName>
        <description>When VGT information needed is checked we need to alert Marie Both Organic and Competitor</description>
        <protected>false</protected>
        <recipients>
            <recipient>marieb@accelentertainment.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Service/VGT_Information_Needed</template>
    </alerts>
    <fieldUpdates>
        <fullName>ACH_Checked_Timestamp</fullName>
        <field>ACH_Checked_Timestamp__c</field>
        <formula>NOW()</formula>
        <name>ACH Checked Timestamp</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Change_ASR_Status_to_Pending_Asset_Alloc</fullName>
        <field>Add_Swap_Reconfigure_Status__c</field>
        <literalValue>Pending Asset Allocation</literalValue>
        <name>Change ASR Status to Pending Asset Alloc</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Change_Status_to_IGB_Approval</fullName>
        <field>Project_Status__c</field>
        <literalValue>IGB Approval</literalValue>
        <name>Change Status to IGB Approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Proj_Status_to_reg_approvals</fullName>
        <field>Project_Status__c</field>
        <literalValue>Regional Approval</literalValue>
        <name>Proj Status to reg Approvals</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Proj_status_to_parts_fulfillment</fullName>
        <field>Project_Status__c</field>
        <literalValue>Parts Fulfillment</literalValue>
        <name>Proj status to parts fulfillment</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Project_Status_Field_Has_Changed</fullName>
        <field>Alert_Project_Status_Changed__c</field>
        <formula>&apos;STAGE INDICATOR &apos;+ Text(Stage_Indicator__c)</formula>
        <name>Project Status Field Has Changed</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Project_Status_Field_Hasn_t_Changed</fullName>
        <field>Alert_Project_Status_Changed__c</field>
        <name>Project Status Field Hasn&apos;t Changed</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Rejected_by_Regional</fullName>
        <field>Add_Swap_Reconfigure_Status__c</field>
        <literalValue>Approval Rejected - Regional Manager</literalValue>
        <name>Rejected by Regional</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Status_to_pending_reg_mgr_approval</fullName>
        <field>Add_Swap_Reconfigure_Status__c</field>
        <literalValue>Pending Regional Manager Approval</literalValue>
        <name>Status to pending reg mgr approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Project_Submitted_Date_field</fullName>
        <field>Project_Submitted_Date__c</field>
        <formula>TODAY()</formula>
        <name>Update &quot;Project Submitted Date&quot; field</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_stage_to_Field_Assessment</fullName>
        <field>Project_Status__c</field>
        <literalValue>Field Assessment</literalValue>
        <name>Update stage to Field Assessment</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>proj_status_rejected</fullName>
        <field>Project_Status__c</field>
        <literalValue>Rejected</literalValue>
        <name>proj status rejected</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>stage_indicator_analysis_rejected</fullName>
        <field>Stage_Indicator__c</field>
        <literalValue>Analysis Team rejected</literalValue>
        <name>stage indicator = analysis rejected</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>stage_indicator_exec_rejected</fullName>
        <field>Stage_Indicator__c</field>
        <literalValue>Executive Team rejected</literalValue>
        <name>stage indicator = exec rejected</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>status_to_pending_exec_approval</fullName>
        <field>Add_Swap_Reconfigure_Status__c</field>
        <literalValue>Pending Executive Approval</literalValue>
        <name>status to pending exec approval</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>status_to_pending_field_assessment</fullName>
        <field>Add_Swap_Reconfigure_Status__c</field>
        <literalValue>Field Assessment In Process</literalValue>
        <name>status to field assessment</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>status_to_pending_machine_assignment</fullName>
        <field>Add_Swap_Reconfigure_Status__c</field>
        <literalValue>Pending Machine Assignment</literalValue>
        <name>status to pending machine assignment</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Assets Allocated</fullName>
        <actions>
            <name>Send_Asset_Located_Email</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Project__c.Assets_Allocated__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Project Status Field Hasn%27t Changed</fullName>
        <actions>
            <name>Project_Status_Field_Hasn_t_Changed</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>Text(PriorValue(Project_Status__c)) == Text(Project_Status__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Project Status Has Changed</fullName>
        <actions>
            <name>Project_Status_Field_Has_Changed</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>IF(And(Text(PRIORVALUE(Project_Status__c))&lt;&gt; Text(Project_Status__c), Not(IsBlank(Text(Stage_Indicator__c)))), True, False)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Timestamp ACH Checked Timestamp</fullName>
        <actions>
            <name>ACH_Checked_Timestamp</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Project__c.ACH_Deposit__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
