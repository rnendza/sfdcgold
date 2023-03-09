@isTest
private class TEST_TimeSlotWrapperCsv {

    @isTest
    static void test_generate_positive() {

        List<TimeSlotWrapper>   tsWraps         = new List<TimeSlotWrapper>();
        TimeSlotWrapperCsv      csvGenerator    = new TimeSlotWrapperCsv();
        DateTime                lastModDatetime = System.now();
        ServiceTerritory        st              = new ServiceTerritory(name='Chicagoland North');
        ServiceTerritoryMember stm              = new ServiceTerritoryMember(ServiceTerritory = st);

        for(Integer i=0;i<10;i++) {
            TimeSlotWrapper tsWrap  = new TimeSlotWrapper();
            TimeSlot  ts = new TimeSlot();
            tsWrap.timeSlot = ts;   //note we can't set the name 'TimeSlotNumber' so it will have to be null for this test.
            tsWrap.name             = 'test svc mbr name '+i;
            tsWrap.dayOfWeek        = 'Monday';
            tsWrap.startTime        =  Time.newInstance(1, 2, 3, 0);
            tsWrap.endTime          =  Time.newInstance(1, 6, 1, 0);
            tsWrap.lastModifiedDate = lastModDatetime;
            tsWrap.svcTerritoryMbr = stm;
            tsWrap.lastModifiedByName = 'lastmodbyname test'+i;
            tsWraps.add(tsWrap);
       }
        String expected =   '' + '"Territory","Time Slot Name","Time Slot Url","Svc Mbr Name","Day of Week","Start Time","Start Time Formatted",' +
                            '"End Time","End Time Formatted","Last Modified Date Time","Last Modified By"\n';

        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();

        for( TimeSlotWrapper tsWrapper : tsWraps ) {
            Time    startTime           = tsWrapper.startTime;
            String  startTimeFormatted  = csvGenerator.formatTime(startTime);
            Time    endTime             = tsWrapper.endTime;
            String  endTimeFormatted    = csvGenerator.formatTime(endTime);
            //note since we can't fake timeslot id it will come back something like baseurl/null
            expected += '"'+ tsWrapper.svcTerritoryMbr.ServiceTerritory.Name + '","","'+baseUrl+'/null","'
                        +tsWrapper.name
                        + '","Monday","' + startTime + '",'+ startTimeFormatted+
                        ',"' + endTime + '",' + endTimeFormatted+ ',"'+lastModDatetime+ '","'+tsWrapper.lastModifiedByName+'"\n' ;
        }
        Test.startTest();

        String csvActual = csvGenerator.generateTimeSlotWrapperCsv(tsWraps);
        System.assertEquals( expected, csvActual );

        Test.stopTest();
    }
}