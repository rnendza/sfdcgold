public class Accel_SelectItem {

    @AuraEnabled public String  label       {get; set;}
    @AuraEnabled public String  value       {get; set;}
    @AuraEnabled public Boolean  selected   {get; set;}

    public Accel_SelectItem( String value, String label, Boolean selected) {
        this(value,label);
        this.selected = selected;
    }
    public Accel_SelectItem( String value, String label) {
        this.label = label;
        this.value = value;
        this.selected = false;
    }
}