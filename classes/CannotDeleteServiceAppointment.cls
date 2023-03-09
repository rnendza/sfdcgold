public class CannotDeleteServiceAppointment {
     public static void NoDeleteServiceAppointment (List<ServiceAppointment> Sas){
        system.debug('before delete trigger');
        String Profid = UserInfo.getProfileId();
         
         String profileName = [SELECT Name FROM Profile WHERE Id =:ProfId].Name;
      //  System.debug('Current User id'+Profid);
       // set<string> strkey = new set<string>(Label.UserGroup.split(','));
     //   System.debug('strkey'+strkey);
        
    
        for (ServiceAppointment sa: sas){
            If(profileName == 'Accel Service User'){
                sa.addError('You cannot delete the Service Appointment');
            }
        }
    }

}