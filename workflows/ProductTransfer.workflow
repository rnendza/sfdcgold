<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Products_Transferred_to_Van</fullName>
        <description>Products Transferred to Van</description>
        <protected>false</protected>
        <recipients>
            <recipient>Parts_Department</recipient>
            <type>role</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Service/Products_Transferred</template>
    </alerts>
</Workflow>
