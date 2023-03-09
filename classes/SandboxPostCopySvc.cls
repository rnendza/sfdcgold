global without sharing class SandboxPostCopySvc implements SandboxPostCopy{

    @TestVisible private static final String INVALID_EMAIL_STRING = '.invalid';

    global void runApexClass(SandboxContext sandboxCtx) {
        this.cleanseEmails();
    }

    public void cleanseEmails() {

        String emailFilter = '%' + INVALID_EMAIL_STRING;
        List<User> users = [
                SELECT Id,Email
                FROM   User
                WHERE  IsActive =   TRUE
                AND    Email LIKE :emailFilter
        ];
        for(User user : users) {
            user.email = user.email.remove(INVALID_EMAIL_STRING);
            System.resetPassword(user.Id, true);

        }

        List<Database.SaveResult>  srs = Database.update(users);

        //  @todo error checking / send email with results etc etc.
    }
}