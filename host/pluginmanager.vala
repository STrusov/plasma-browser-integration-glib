
namespace PluginManager {

void add_plugin(AbstractBrowserPlugin plugin) {
    if (plugins == null)
        plugins = new HashTable<string, AbstractBrowserPlugin>(str_hash, str_equal);
    plugins.insert(plugin.subsystem_name, plugin);
    Connection.create(on_data_received);
}

AbstractBrowserPlugin plugin_for_subsystem(string name) {
    return plugins.get(name);
}

HashTable<string, AbstractBrowserPlugin> plugins;

// load_plugin()
// unload_plugin()

// settings_changed()

// known_plugin_subsystems()

void on_data_received(Json.Object json) {
    if (!json.has_member("subsystem") || !json.has_member("event"))
        return;
    // get_string_member() assumes the member exists.
    // It internally uses g_return_val_if_fail() about which it is documented:
    // Any failure of such a pre-condition assertion is considered a programming
    // error on the part of the caller of the public API.
    // So, the browser extension shall supply a correct JSON.
    string subsystem = json.get_string_member("subsystem");
    AbstractBrowserPlugin plugin = plugin_for_subsystem(subsystem);
    if (plugin == null) // || !plugin.enabled
        return;
    string event = json.get_string_member("event");
    if (json.has_member("serial")) {
        int64 serial = json.get_int_member("serial");
        critical("serial " + int64.FORMAT, serial);
        return;
    }
    plugin.handle_data(event, json);
}

}
