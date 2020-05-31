
class Settings : AbstractBrowserPlugin, Object {
    public unowned string subsystem_name() { return "settings"; }

    public void handle_data(string event, Json.Object json) {
        debug("settings event: %s.", event);
        switch (event) {
        case "setEnvironment":
            string name = json.get_string_member("browserName");
            Mpris mpris = (Mpris)PluginManager.plugin_for_subsystem("mpris");
            // TODO: vivaldi, brave etc
            switch (name) {
            case "firefox": mpris.identity = mpris.desktop_entry = name; break;
            default:
                break;
            }
            break;
        case "changed":
            break;
        default:
            warning("Unknown event: %s.", event);
            break;
        }
    }
    public override Json.Object? handle_request(int64 serial, string event, Json.Object data) {
        var ret = new Json.Object();
        switch (event) {
        case "getSubsystemStatus":
            PluginManager.foreach_known_plugin((name, plugin) => {
                Json.Object details = status();
                details.set_int_member("version", plugin.protocol_version());
                details.set_boolean_member("loaded", true); // TODO: is_loaded()
                ret.set_object_member(name, details);
            });
            break;
        case "getVersion":
            ret.set_string_member("host", host_version_string);
            break;
        default:
            warning("Unknown serial event: %s.", event);
            ret = null;
            break;
        }
        return ret;
    }
}
