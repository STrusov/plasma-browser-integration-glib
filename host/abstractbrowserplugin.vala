
interface AbstractBrowserPlugin : Object {

    public abstract string subsystem_name { get; }

    public abstract void handle_data(string event, Json.Object json);

    public void send_data(string action, Json.Object? payload = null) {
        info(action);
        var data = new Json.Object();
        data.set_string_member("subsystem", subsystem_name);
        data.set_string_member("action", action);
        if (payload != null)
            data.set_object_member("payload", payload);
        Connection.send_data(data);
    }

}
