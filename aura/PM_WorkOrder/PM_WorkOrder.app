<aura:application extends="force:slds" access="GLOBAL">
<!--<aura:application extends="ltng:outApp" access="GLOBAL">-->
    <!--<aura:dependency resource="c:PM_Work_Order_Line_Item"/>-->
    <!--<aura:dependency resource="c:*" type="COMPONENT"/>-->
	 <aura:attribute name="selectedLookUpRecord" type="sObject" default="{}"/>
	
   <c:PM_Work_Order_Line_Item />
</aura:application>