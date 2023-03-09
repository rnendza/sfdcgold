public virtual class CsvGenerator{

    public String line(String[] cells) {
        return String.join(cells, ',') + '\n';
    }
    public String format(Time t) {
        return t != null ? '"' + t + '"' : '""';
    }
    public String format(DateTime dt) {
        return dt != null ? '"' + dt + '"' : '""';
    }
    public String formatTime(Time t) {
        String s = '';
        if (t != null) {
            DateTime dt = DateTime.newInstance(Date.today(), t);
            s += '"';
            s += dt.format('h:mm a');
            s += '"';
        } else {
            s += '""';
        }
        return s;
    }
    public String format(String s) {
        return s != null ? '"' + s.escapeCsv() + '"' : '""';
    }
}