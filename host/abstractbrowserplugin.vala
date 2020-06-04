
abstract class AbstractBrowserPlugin : Object {

    public abstract unowned string subsystem_name();

    internal virtual int protocol_version() { return 1; }

    protected virtual Json.Object status() { return new Json.Object(); }

    internal abstract void handle_data(string event, Json.Object json);
    internal virtual Json.Object? handle_request(int64 serial, string event, Json.Object data) {
        warning("%s do not expect request %s %lli", subsystem_name(), event, serial);
        return null;
    }

    internal void send_data(string action, Json.Object? payload = null) {
        var data = new Json.Object();
        data.set_string_member("subsystem", subsystem_name());
        data.set_string_member("action", action);
        if (payload != null)
            data.set_object_member("payload", payload);
        Connection.send_data(data);
    }

    internal void send_reply(int64 request_serial, Json.Object? payload) {
        var data = new Json.Object();
        data.set_int_member("replyToSerial", request_serial);
        if (payload != null)
            data.set_object_member("payload", payload);
        Connection.send_data(data);
    }

}
