<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Notify_Warehouse_Product_Consumed_from_Van</fullName>
        <description>Notify Warehouse Product Consumed from Van</description>
        <protected>false</protected>
        <recipients>
            <recipient>Parts_Department</recipient>
            <type>role</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Service/Parts_Consumed_Notification</template>
    </alerts>
</Workflow>
