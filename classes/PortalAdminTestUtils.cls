@IsTest
public class PortalAdminTestUtils {

    public static final String SFDCPAADVISORIES             = 'paadvisories';
    public static final Integer NUM_PA_ADVISORIES           = 10;

    public static Map<String,Object> createAllPaData() {
        Datetime start = System.now();
        LIST<PA_Advisory__c> paAdvisories = createPaAdvisoryData(NUM_PA_ADVISORIES);
        Map<String,Object> m  = new Map<String,Object>{
                SFDCPAADVISORIES    => paAdvisories
        };
        Datetime endTime = System.now();
        Long millis = endTime.getTime() - start.getTime();

        String msg = '';
        msg = '\nPa_Advisories: '+paAdvisories.size()+'\n';
        msg += 'Elapsed Time: '+millis + ' milliseconds to create.\n';
        System.debug('\n\n---> Portal Admin Test Data TEST DATA <----'+msg);
        return m;
    }

    public static List<PA_Advisory__c> buildPaAdvisoryData(Integer iNumRows) {
        List<PA_Advisory__c> advisories = new List<PA_Advisory__c>();
        for(Integer i = 0; i<iNumRows; i++) {
            PA_Advisory__c advisory = new PA_Advisory__c(
                    Advisory_Number__c = 'VGT-0000'+i,
                    Advisory_Date__c = Date.today(),
                    First_Name__c = 'First'+i,
                    Last_Name__c = 'Last'+i
            );
            advisories.add(advisory);
        }
        return advisories;
    }

    public static List<PA_Advisory__c> createPaAdvisoryData(Integer iNumRows) {
        List<PA_Advisory__c> advisories = buildPaAdvisoryData(iNumRows);
        insert advisories;
        return advisories;
    }
}