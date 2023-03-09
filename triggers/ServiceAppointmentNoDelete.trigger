trigger ServiceAppointmentNoDelete on ServiceAppointment (before delete) {
    
       if(Trigger.isBefore){
        System.debug('Inside the Trigger');
        CannotDeleteServiceAppointment.NoDeleteServiceAppointment(Trigger.Old);
    }
}