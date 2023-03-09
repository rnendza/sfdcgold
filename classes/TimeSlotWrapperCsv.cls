public class TimeSlotWrapperCsv {
    /**
     *
     *
     * @param tsWraps
     *
     * @return
     */
    public String generateTimeSlotWrapperCsv(List<TimeSlotWrapper> tsWraps) {
        String s = line(new String[] {
                format('Territory'),
                format('Time Slot Name'),
                format('Time Slot Url'),
                format('Svc Mbr Name'),
                format('Day of Week'),
                format('Start Time'),
                format('Start Time Formatted'),
                format('End Time'),
                format('End Time Formatted'),
                format('Last Modified Date Time'),
                format('Last Modified By')
        });
        String baseUrl =  URL.getSalesforceBaseUrl().toExternalForm();

        for (TimeSlotWrapper tsWrap : tsWraps) {
            String tsUrl = baseUrl+'/'+tsWrap.timeSlotId;
            s += line(new String[] {
                    format(tsWrap.svcTerritoryMbr.ServiceTerritory.Name),
                    format(tsWrap.timeSlot.TimeSlotNumber),
                    format(tsUrl),
                    format(tsWrap.name),
                    format(tsWrap.dayOfWeek),
                    format(tsWrap.startTime),
                    formatTime(tsWrap.startTime),
                    format(tsWrap.endTime),
                    formatTime(tsWrap.endTime),
                    format(tsWrap.lastModifiedDate),
                    format(tsWrap.lastModifiedByName)
            });
        }
        return s;
    }
    private String line(String[] cells) {
        return String.join(cells, ',') + '\n';
    }
    private String format(Time t) {
        return t != null ? '"' + t + '"' : '""';
    }
    private String format(DateTime dt) {
        return dt != null ? '"' + dt + '"' : '""';
    }
    public String formatTime(Time t) {
        String s = '';
        if(t!=null) {
            DateTime dt = DateTime.newInstance(Date.today(), t);
            s += '"';
            s += dt.format('h:mm a');
            s += '"';
        } else {
            s+= '""';
        }
        return s;
    }
//    private String format(Date d)    {
//        return d != null ? '"' + d.format().escapeCsv() + '"' : '""';
//    }
    private String format(String s) {
        return s != null ? '"' + s.escapeCsv() + '"' : '""';
    }
//    private String format(Decimal d, Integer scale) {
//        return d != null ? String.valueOf(d.setScale(scale)) : '';
//    }
//    private String format(Decimal d) {
//        return format(d, 2);
//    }
}