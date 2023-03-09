/**
 * @see https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_restresponse.htm
 */
public class HttpStatusCodes {
    public final static Integer OK = 200;
    public final static Integer CREATED = 201;
    public final static Integer ACCEPTED = 202;
    public final static Integer NO_CONTENT = 204;
    public final static Integer PARTIAL_CONTENT = 206;
    public final static Integer MULTIPLE_CHOICES = 300;
    public final static Integer MOVED_PERMANENTLY = 301;
    public final static Integer FOUND = 302;
    public final static Integer NOT_MODIFIED = 304;
    public final static Integer BAD_REQUEST = 400;
    public final static Integer UNAUTHORIZED = 401;
    public final static Integer FORBIDDEN = 403;
    public final static Integer NOT_FOUND = 404;
    public final static Integer METHOD_NOT_ALLOWED = 405;
    public final static Integer NOT_ACCEPTABLE = 406;
    public final static Integer CONFLICT = 409;
    public final static Integer GONE = 410;
    public final static Integer PRECONDITION_FAILED = 412;
    public final static Integer REQUEST_ENTITY_TOO_LARGE = 413;
    public final static Integer REQUEST_URI_TOO_LARGE = 414;
    public final static Integer UNSUPPORTED_MEDIA_TYPE = 415;
    public final static Integer EXPECTATION_FAILED = 417;
    public final static Integer INTERNAL_SERVER_ERROR = 500;
    public final static Integer SERVER_UNAVAILABLE = 503;
}