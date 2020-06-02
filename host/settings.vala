
class Settings : AbstractBrowserPlugin, Object {
    public unowned string subsystem_name() { return "settings"; }

    public void handle_data(string event, Json.Object json) {
        debug("settings event: %s.", event);
        switch (event) {
        case "setEnvironment":
            string name = json.get_string_member("browserName");
            Mpris mpris = (Mpris)PluginManager.plugin_for_subsystem("mpris");
            // Most chromium-based browsers just impersonate Chromium nowadays to keep websites from locking them out
            // so we'll need to make an educated guess from our parent process
            if (name == "chrome" || name == "chromium") {
                var file = FileStream.open("/proc/%d/comm".printf(Posix.getppid()),"r");
                string parent_name = file.read_line();
                if (parent_name != null && parent_name.length > 0)
                    name = parent_name;
            }
            switch (name) {
            case "brave":
                mpris.identity = "Brave";
                mpris.desktop_entry = "brave-browser";
                break;
            case "chrome":
                mpris.identity = mpris.desktop_entry = "google-chrome";
                break;
            case "chromium":
                mpris.identity = mpris.desktop_entry = "chromium-browser";
                break;
            default:
                break;
            case "firefox":
            case "opera":
                mpris.identity = mpris.desktop_entry = name;
                break;
            case "vivaldi":
                mpris.identity = name;
                mpris.desktop_entry = "vivaldi-stable";
                break;
            case "yandex_browser":
                // FIXME: Gnome hides this because of '-beta'
                mpris.identity = mpris.desktop_entry = "yandex-browser-beta";
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
