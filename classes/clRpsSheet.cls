/**
 * Main wrapper for REST operations for RPS Sheets.
 * Please do not remove any properties from here!
 */
public class clRpsSheet {

    public String locName;
    public String locSecurityKey;
    public String locAccessTime;
    public String locCollectionNotes;
    public String locRmName;
    public String locCollectionContactName;
    public String rpsId;
    public String rpsName;
    public String rpsCollectionType;
    public String rpsStatus;
    public String access;
    public clAddress locShippingAddress;

    public clRpsSheet(clRouteProcessingSheetsController.RpsWrapper wrap) {
        this.locName = wrap.locName;
        this.locSecurityKey = wrap.locSecurityKey;
        this.locRmName = wrap.locRmName;
        this.locCollectionContactName = wrap.locCollectionContactName;
        this.locAccessTime = wrap.locAccessTime;
        this.locCollectionNotes = wrap.locCollectionNotes;
        this.rpsId = wrap.rpsId;
        this.rpsName = wrap.rpsName;
        this.rpsCollectionType = wrap.rpsCollectionType;
        this.rpsStatus = wrap.rpsStatus;
        this.locShippingAddress = this.populateShippingAddress(wrap);
    }

    public clAddress populateShippingAddress(clRouteProcessingSheetsController.RpsWrapper wrap) {
        locShippingAddress = new clAddress();
        locShippingAddress.longitude = wrap.longitude;
        locShippingAddress.latitude = wrap.latitude;
        locShippingAddress.displayAddress = wrap.formattedAddressText;
        return locShippingAddress;
    }
}