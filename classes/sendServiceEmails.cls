public class sendServiceEmails {

    public static void sendServiceEmails () {
        
        //identify who will be receiving the emails
        String [] toAddresses = new String[] {'salesforce@accelentertainment.com'};
        String [] ccAddresses = new String[] {'DailyServiceCallLogs@accelentertainment.com', 'PendingIssuesReport@accelentertainment.com','CallCenterRepresentatives@accelentertainment.com'};
      

        
        //render the visualforce and apex reports as blobs to be inserted as attachments
        PageReference dcl = page.dailycalllog;
        PageReference pi = page.pendingissues;
        Blob dclcontent;
        Blob picontent;
        //the following is required in order to pass unit tests for production deployment
        if(Test.isRunningTest()){
            dclcontent = blob.valueOf('Unit.Test');
            picontent = blob.valueOf('Unit.test');
        }else{
            dclcontent = dcl.getContentAsPDF();
            picontent = pi.getContentAsPDF();
        }
        
        //create the email object and the attachment objects
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        Messaging.EmailFileAttachment efa1 = new Messaging.EmailFileAttachment();
        Messaging.EmailFileAttachment efa2 = new Messaging.EmailFileAttachment();
        
        //set the file names appropriately and attach the blob content to the attachment files
        efa1.SetFileName('DailyCallLog'+date.Today().addDays(-1).format().replace('/', '-')+'.pdf');
        efa1.setBody(dclcontent);
        efa2.SetFileName('PendingIssues'+date.Today().addDays(-1).format().replace('/', '-')+'.pdf');
        efa2.setBody(picontent);
        
        //set the email object's properties
        email.setOrgWideEmailAddressId('0D21I000000g5CxSAI');
        email.setSubject('Daily Call Log & Pending Issues for '+ date.Today().addDays(-1).format().replace('/', '-'));
        email.setToAddresses(toAddresses);
        email.setBccAddresses(ccAddresses);
        email.setPlainTextBody('Attached are the daily call log and pending issues for '+date.Today().addDays(-1).format().replace('/', '-'));
        email.setFileAttachments(new Messaging.EmailFileAttachment[] { efa1, efa2 });
        
        //send the completed email object
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
}