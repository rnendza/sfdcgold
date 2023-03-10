public class SelectItem {

    @AuraEnabled public String  label  {get; set;}
    @AuraEnabled public String  value  {get; set;}
    @AuraEnabled public Boolean  selected  {get; set;}

    public SelectItem( String value, String label, Boolean selected) {
        this(label,value);
        this.selected = selected;
    }
    public SelectItem( String value, String label) {
        this.label = label;
        this.value = value;
        this.selected = false;
    }
}