/**
 * Business Logic / Svc Class for PA_Advisory__c.
 */
public with sharing class PaAdvisoryGallerySvc {

    public static Boolean DEBUG_QUERY = false;  // Turn Debug logging on for the entire class.

    /**
     * Retrieve PA_Advisory__c records for the passed advisory ids WITH Base 64 encoded data.
     *
     * @param advisoryIds       A set of Pa_Advisory__c.Id values.
     * @return                  A List of Pa_Advisory__c sObjects.
     */
    public static List<PA_Advisory__c> retrievePaAdvisoriesForPdfExport(Set<Id> advisoryIds) {
        List<PA_Advisory__c> advisories = [
                SELECT Id,Name,Advisory_Date__c,Image_Base_64_String__c,Photo__c,Full_Name__c
                FROM   PA_Advisory__c
                WHERE  Id IN :advisoryIds
                AND    Visible__c = TRUE
        ];
        return advisories;
    }

    /**
     * Retrieves a list of PA_Advisory__c sObjects for the provided criteria.
     *
     * @param iLimit                The limit on number of records to retrieve.
     * @param advisoryStartDate     The PA_Advisory__c.Advisory_Date__c ( greater than or equal ).
     * @param advisoryEndDate       The PA_Advisory__c.Advisory_Date__c ( less than or equal ).
     *
     * @return                      A List of PA_Advisory__c sObjects.
     */
    public static List<PA_Advisory__c> retrievePaAdvisories(Integer iLimit,Date advisoryStartDate, Date advisoryEndDate) {
        String q = '';
        q+= ' SELECT   Id,Name,Advisory_Date__c,Full_Name__c,Photo__c,Last_Name__c,Advisory_Number__c, ';
        q+= '          Exclusion_Type__c, Exclusion_Period__c, City__c ';
        q+= ' FROM     PA_Advisory__c ';
        q+= ' WHERE    Visible__c = TRUE ';
        if(advisoryStartDate != null ) {
            q+= ' AND Advisory_Date__c >= :advisoryStartDate ';
        }
        if(advisoryEndDate != null) {
            q+= ' AND Advisory_Date__c <= :advisoryEndDate ';
        }
        q+= ' ORDER BY NAME ASC ';
        q+= ' LIMIT    :iLimit ';

        List<PA_Advisory__c> advisories = Database.query(q);
        return advisories;
    }

    /**
     * Retrieves a list of PA_Advisory__c sObjects for the provided criteria.
     *
     * @param iOffset               The offset for the SOQL Statement.
     * @param iLimit                The limit on number of records to retrieve.
     * @param advisoryStartDate     The PA_Advisory__c.Advisory_Date__c ( greater than or equal ).
     * @param advisoryEndDate       The PA_Advisory__c.Advisory_Date__c ( less than or equal ).
     * @param isVisible             The PA_Advisory__c.Visible__c value;
     * @param fullName              The PA_Advisory__c.Full_Name__c value;
     * @param city                  The PA_Advisory__c.City__c value;
     *
     * @return                      A List of PA_Advisory__c sObjects.
     *
     * @implNote                    DUE to SFDC Limitations the largest offset number is 2000.
     *                              meaning you will never get more then 2K records without advanced
     *                              custom queryMore implementations.
     *
     * @see https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select_offset.htm
     */
    public static List<PA_Advisory__c> retrievePaAdvisoriesAdvancedSearch(  Integer iOffset,
                                                                            Integer iLimit,
                                                                            Date advisoryStartDate,
                                                                            Date advisoryEndDate,
                                                                            Boolean isVisible,
                                                                            String fullName,
                                                                            String city) {
        String q = '';
        String filter;

        q+= ' SELECT   Id,Name,Advisory_Date__c,Full_Name__c,Photo__c,Last_Name__c,First_Name__c,Advisory_Number__c, ';
        q+= '          Exclusion_Type__c, Exclusion_Period__c,City__c, Request_Date__c ';
        q+= ' FROM     PA_Advisory__c ';

        if(isVisible != null) {
            filter = ' WHERE Visible__c = :isVisible ';
        }
        if(advisoryStartDate != null) {
            if(filter == null) {
                filter = ' WHERE Advisory_Date__c >= :advisoryStartDate ';
            } else {
                filter += ' AND Advisory_Date__c >= :advisoryStartDate ';
            }
        }
        if(advisoryEndDate != null) {
            if(filter == null) {
                filter = ' WHERE Advisory_Date__c <= :advisoryEndDate ';
            } else {
                filter += ' AND Advisory_Date__c <= :advisoryEndDate ';
            }
        }
        if(fullName != null) {
            String sFirstName = '%'+fullName+'%';
            String sLastName  = '%'+fullName+'%';
            if(filter == null) {
                filter = ' WHERE (First_Name__c LIKE :sFirstName OR Last_Name__c LIKE :sFirstName) ';
            } else {
                filter += ' AND (First_Name__c LIKE :sFirstName OR Last_Name__c LIKE :sLastName) ';
            }
        }
        if(city != null) {
            String sCity = '%'+city+'%';
            if(filter == null) {
                filter = ' WHERE City__c LIKE :sCity ';
            } else {
                filter += ' AND City__c LIKE :sCity';
            }
        }

        if(filter != null) {
            q += filter;
        }

        q += ' ORDER BY Last_Name__c ASC ';
        if(iLimit != null) {
            q += ' LIMIT  :iLimit ';
        }
        if(iOffset != null) {
            q += ' OFFSET :iOffset ';
        }

        if(DEBUG_QUERY) {
            System.debug('---> query: ' + q);
        }
        List<PA_Advisory__c> advisories = Database.query(q);
        return advisories;
    }
    /**
     * Gets a count of what the query will retrieve. [ Select COUNT() ... ].
     *
     * @param iOffset               The offset for the SOQL Statement.
     * @param iLimit                The limit on number of records to retrieve.
     * @param advisoryStartDate     The PA_Advisory__c.Advisory_Date__c ( greater than or equal ).
     * @param advisoryEndDate       The PA_Advisory__c.Advisory_Date__c ( less than or equal ).
     * @param isVisible             The PA_Advisory__c.Visible__c value;
     * @param fullName              The PA_Advisory__c.Full_Name__c value;
     * @param city                  The PA_Advisory__c.City__c value;
     *
     * @return                      A List of PA_Advisory__c sObjects.
     *
     */
    public static Integer retrievePaAdvisoriesAdvancedSearchTotalRecords(       Integer iOffset,
                                                                                Integer iLimit,
                                                                                Date advisoryStartDate,
                                                                                Date advisoryEndDate,
                                                                                Boolean isVisible,
                                                                                String fullName,
                                                                                String city) {
        String q = '';
        String filter;

        q+= ' SELECT   Count() ';
        q+= ' FROM     PA_Advisory__c ';

        if(isVisible != null) {
            filter = ' WHERE Visible__c = :isVisible ';
        }
        if(advisoryStartDate != null) {
            if(filter == null) {
                filter = ' WHERE Advisory_Date__c >= :advisoryStartDate ';
            } else {
                filter += ' AND Advisory_Date__c >= :advisoryStartDate ';
            }
        }
        if(advisoryEndDate != null) {
            if(filter == null) {
                filter = ' WHERE Advisory_Date__c <= :advisoryEndDate ';
            } else {
                filter += ' AND Advisory_Date__c <= :advisoryEndDate ';
            }
        }
        if(fullName != null) {
            String sFirstName = '%'+fullName+'%';
            String sLastName  = '%'+fullName+'%';
            if(filter == null) {
                filter = ' WHERE (First_Name__c LIKE :sFirstName OR Last_Name__c LIKE :sFirstName) ';
            } else {
                filter += ' AND (First_Name__c LIKE :sFirstName OR Last_Name__c LIKE :sLastName) ';
            }
        }
        if(city != null) {
            String sCity = '%'+city+'%';
            if(filter == null) {
                filter = ' WHERE City__c LIKE :sCity ';
            } else {
                filter += ' AND City__c LIKE :sCity';
            }
        }

        if(filter != null) {
            q += filter;
        }
        if(iLimit != null) {
            q += ' LIMIT  :iLimit ';
        }
        if(DEBUG_QUERY) {
            System.debug('---> query: ' + q);
        }
        Integer iCount = Database.countQuery(q);
        return iCount;
    }

    /**
     * Retrieve a single PA_Advisory__c sObject record.
     *
     * @param paAdvisoryId  The PA_Advisory__c.Id field.
     * @return              A PA_Advisory__c sObject with all fields.
     */
    public static PA_Advisory__c retrievePaAdvisory(Id paAdvisoryId) {
        PA_Advisory__c advisory;
        String q = '';
        q += 'SELECT {0} ';
        q += 'FROM   Pa_Advisory__c ';
        q += 'WHERE  Id = :paAdvisoryId ';

        String formattedQuery = String.format(q,getAllPaAdvisoryFields());
        List<PA_Advisory__c>paAdvisories = Database.query(formattedQuery);

        advisory = !paAdvisories.isEmpty() ? paAdvisories[0] : null;
        return advisory;
    }


    public static List<PA_Advisory__c> retrievePaAdvisoriesExportData(Boolean isVisible) {
        List<PA_Advisory__c> advisories;
        String q = '';
        String filter;

        q += 'SELECT {0} ';
        q += 'FROM   Pa_Advisory__c ';

        if(isVisible != null) {
            filter = ' WHERE Visible__c = :isVisible ';
        }
                              
        if(filter != null) {
            q+= filter;
        }

        String formattedQuery = String.format(q,getAllPaAdvisoryFields());
        advisories = Database.query(formattedQuery);

        return advisories;
    }

    /**
     * Can be used to simulate a SELECT * query.
     *
     * @return  All Fields in PA_Advisory__c.
     */
    public static List<String>  getAllPaAdvisoryFields() {
        Map<String, Schema.SObjectField> fieldsMap = PA_Advisory__c.sObjectType.getDescribe().fields.getMap();
        String sFields = String.join(new List<String>(fieldsMap.keySet()), ',');
        List<String> fields = new List<String>{sfields};
        return fields;
    }
}