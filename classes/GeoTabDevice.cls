public class GeoTabDevice {

    @AuraEnabled public String id;
    @AuraEnabled public String serialNumber;
    @AuraEnabled public boolean obdAlertEnabled;
//    public Object[] auxWarningSpeed;
//    public Object[] enableAuxWarning;
    @AuraEnabled public boolean enableControlExternalRelay;
    @AuraEnabled public Integer externalDeviceShutDownDelay;	//0
    @AuraEnabled public Integer immobilizeArming;	//30
    @AuraEnabled public boolean immobilizeUnit;
//    public Object[] isAuxIgnTrigger;
//    public Object[] isAuxInverted;
    public Integer accelerationWarningThreshold;	//22
    public Integer accelerometerThresholdWarningFactor;	//0
    public Integer brakingWarningThreshold;	//-34
    public Integer corneringWarningThreshold;	//26
    public boolean enableBeepOnDangerousDriving;
    public boolean enableBeepOnRpm;
    public Integer engineHourOffset;	//0
    @AuraEnabled public boolean isActiveTrackingEnabled;
    public boolean isDriverSeatbeltWarningOn;
    public boolean isPassengerSeatbeltWarningOn;
    public boolean isReverseDetectOn;
    public boolean isIoxConnectionEnabled;
    public Integer odometerFactor;	//1
    public Integer odometerOffset;	//0
    public Integer rpmValue;	//3500
    public Integer seatbeltWarningSpeed;	//10
    @AuraEnabled public String activeFrom;	//2022-04-15T13:19:17.877Z
    @AuraEnabled public String activeTo;	//2050-01-01T00:00:00.000Z
//    public Object[] autoGroups;
//    public Object[] customParameters;
    public boolean disableBuzzer;
    public boolean enableBeepOnIdle;
    public boolean enableMustReprogram;
    public boolean enableSpeedWarning;
    public String engineType;	//EngineTypeGenericId
    public String engineVehicleIdentificationNumber;	//5XYZUDLB4HG389750
    public boolean ensureHotStart;
    public Integer gpsOffDelay;	//0
    public Integer idleMinutes;	//3
    public boolean isSpeedIndicator;
    @AuraEnabled public String licensePlate;	//
    @AuraEnabled public String licenseState;	//
    public Integer major;	//36
    public Integer minAccidentSpeed;	//4
    public Integer minor;	//23
    public Integer parameterVersion;	//1
    public boolean pinDevice;
    public Integer speedingOff;	//90
    public Integer speedingOn;	//100
    @AuraEnabled public String vehicleIdentificationNumber;	//5XYZUDLB4HG389750
    public String goTalkLanguage;	//English
    public Integer fuelTankCapacity;	//0
//    public Object[] wifiHotspotLimits;
    public Integer parameterVersionOnDevice;	//1
    public String comment;	//
//    public Object[] groups;
    @AuraEnabled public String timeZoneId;	//America/New_York
    //public Object deviceFlags;
    @AuraEnabled public String deviceType;	//GO9
    public String ignoreDownloadsUntil;	//1986-01-01T00:00:00.000Z
    public Integer maxSecondsBetweenLogs;	//200
    @AuraEnabled public String name;	//DAN LANNO
    @AuraEnabled public Integer productId;	//120
    public String timeToDownload;	//1.00:00:00
    @AuraEnabled public String workTime;	//WorkTimeStandardHoursId
//    public Object[] devicePlans;
//    public Object[] devicePlanBillingInfo;
//    public Object[] customProperties;
}