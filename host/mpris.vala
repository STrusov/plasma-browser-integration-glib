

/** [[https://specifications.freedesktop.org/mpris-spec/latest/|MPRIS D-Bus Interface Specification]] */
class Mpris : AbstractBrowserPlugin, Object {

    public string subsystem_name { get { return "mpris"; } }

    /** [[https://specifications.freedesktop.org/mpris-spec/latest/Media_Player.html|Specification]] */
    [DBus(name = "org.mpris.MediaPlayer2")]
    class MediaPlayer2 : Object {
        Mpris impl;

        public MediaPlayer2(Mpris impl) { this.impl = impl; }

        public void Raise() throws GLib.Error { impl.raise(); }
        public void Quit()  throws GLib.Error { impl.quit(); }
        public bool CanQuit          { get { return false; } }
        public bool Fullscreen       { get; set; default = false; }
        public bool CanSetFullscreen { get; private set; default = false; }
        public bool CanRaise         { get { return true; } }
        public bool HasTrackList     { get { return false; } }
        public string Identity       { get { return impl.identity; } }
        public string DesktopEntry   { get { return impl.desktop_entry; } }
        public string[] SupportedUriSchemes { owned get { return {}; } }
        public string[] SupportedMimeTypes  { owned get { return {}; } }
        internal void set_can_set_fullscreen(bool v) { CanSetFullscreen = v; }

        /** [[https://specifications.freedesktop.org/mpris-spec/latest/Player_Interface.html|Specification]] */
        [DBus(name = "org.mpris.MediaPlayer2.Player")]
        protected class Player : Object {
            Mpris impl;

            public Player(Mpris impl) { this.impl = impl; }

            public void Next()      throws GLib.Error { impl.next(); }
            public void Previous()  throws GLib.Error { impl.previous(); }
            public void Pause()     throws GLib.Error { impl.pause(); }
            public void PlayPause() throws GLib.Error { impl.play_pause(); }
            public void Stop()      throws GLib.Error { impl.stop(); }
            public void Play()      throws GLib.Error { impl.play(); }
            public void Seek(int64 Offset) throws GLib.Error {
                impl.seek(Offset);
            }
            public void SetPosition(ObjectPath TrackId, int64 Position) throws GLib.Error {
                impl.set_position(TrackId, Position);
            }
            public void OpenUri(string Uri) throws GLib.Error { /* noop */ }

            public signal void Seeked(int64 Position);

            public string PlaybackStatus { get; private set; default = "Stopped"; }
            public string LoopStatus { get; set; default = "None"; }
            public double Rate { get; set; default = 1.0; }
//            public bool Shuffle { get; set; }
            public HashTable<string, Variant> Metadata { get; private set; }

            internal bool muted = false;
            private double volume = 1.0;
            public double Volume {
                get { return muted ? 0.0 : volume; }
                set { volume = value; }
            }
            public int64 Position     { get; set; default = 0; }
            public double MinimumRate { get { return 0.01; } }
            public double MaximumRate { get { return 32; } }
            public bool CanGoNext     { get; private set; default = false; }
            public bool CanGoPrevious { get; private set; default = false; }
            public bool CanPlay       { get { return CanControl; } }
            public bool CanPause      { get { return CanControl; } }
            public bool CanSeek       { get; private set; default = false; }
            public bool CanControl    { get { return true; } }

            private int64 _length = 0;
            [CCode(notify = false)]
            internal int64 length {
                get { return _length; }
                set {
                    _length = value;
                    CanSeek = (value > 0);
                    // TODO: Metadata
                }
            }
            internal void set_playback_status(string status) {
                if (PlaybackStatus != status)
                    PlaybackStatus = status;
            }
            internal void process_callbacks(Json.Array data) {

            }
            internal void process_metadata(Json.Object data) {

            }
        }
    } // class MediaPlayer2

    public Mpris() {
        mp = new MediaPlayer2(this);
        player = new MediaPlayer2.Player(this);
        Bus.own_name(BusType.SESSION,
            // ...each additional instance should request a unique bus name,
            // adding a dot and a unique identifier to its usual bus name.
            // According to the D-Bus specification, the unique identifier
            // "must only contain the ASCII characters '[A-Z][a-z][0-9]_-'"
            // and "must not begin with a digit".
            "org.mpris.MediaPlayer2.plasma-browser-integration.h%d"
                                            .printf(Posix.getpid()),
            BusNameOwnerFlags.NONE,
            (conn, name) => {
                dbus_conn = conn;
                try {
                    conn.register_object("/org/mpris/MediaPlayer2", mp);
                    conn.register_object("/org/mpris/MediaPlayer2", player);
                } catch (IOError e) {
                    critical("Unable to register object: %s", e.message);
                }
            },
            (conn, name) => info("Bus name %s aquired.", name),
            (conn, name) => critical("Bus name %s lost.", name)
        );
        property_changes[0] = new HashTable<string, Variant>(str_hash, str_equal);
        property_changes[1] = new HashTable<string, Variant>(str_hash, str_equal);
        // FIXME: does the original host handle property changes made by D-Bus?
        mp.notify.connect_after(mp_property_changed);
        player.notify.connect_after(player_property_changed);
    }

    DBusConnection dbus_conn;
    HashTable<string, Variant> property_changes[2];
    uint pending = 0;

    void mp_property_changed(Object source, ParamSpec property) {
        shedule_property_changes(source, property, 0);
    }
    void player_property_changed(Object source, ParamSpec property) {
        shedule_property_changes(source, property, 1);
    }
    void shedule_property_changes(Object source, ParamSpec property, int id) {
        debug("%s.%s changed.", source.get_type().name(), property.name);
        var val = Value(property.value_type);
        source.get_property(property.name, ref val);
        switch (property.value_type) {
        case Type.INT64:  property_changes[id][property.name] = val.get_int64();
            break;
        case Type.DOUBLE: property_changes[id][property.name] = val.get_double();
            break;
        case Type.STRING: property_changes[id][property.name] = val.get_string();
            break;
        case Type.BOOLEAN: property_changes[id][property.name] = val.get_boolean();
            break;
        default: warning("%s", property.value_type.qname().to_string());
            break;
        }
        if (pending == 0)
            pending = Timeout.add((1000/60/2), send_property_changes);
    }
    bool send_property_changes() {
        pending = 0;
        string names[] = {
            "org.mpris.MediaPlayer2",
            "org.mpris.MediaPlayer2.Player"
        };
        for (int i = 0; i < 2; ++i) {
            unowned var iface = property_changes[i];
            if (iface.length == 0)
                continue;
            var builder = new VariantBuilder(VariantType.ARRAY);
            var iter = HashTableIter<string, Variant>(iface);
            unowned string name;
            unowned Variant val;
            while (iter.next(out name, out val)) {
                builder.add("{sv}", name, val);
            }
            iface.remove_all();
            var changes = new Variant("(sa{sv}as)", names[i], builder);
            debug("send_property_changes: %s", changes.print(false));
            try {
                dbus_conn.emit_signal(null, "/org/mpris/MediaPlayer2",
                                      "org.freedesktop.DBus.Properties",
                                      "PropertiesChanged", changes);
            } catch (Error e) {
                warning("emit_signal failed: %s", e.message);
            }
        }
        return false;
    }

    MediaPlayer2    mp;
    void raise() {
        if (mp.CanRaise)
            send_data("raise");
    }
    void quit() {
        if (mp.CanQuit)
            // FIXME: unimplemented
            send_data("quit");
    }
    string identity {
        get { return "identity"; }
    }
    string desktop_entry {
        get { return "desktop_entry"; }
    }

    MediaPlayer2.Player player;
    void next() {
        if (player.CanGoNext)
            send_data("next");
    }
    void previous() {
        if (player.CanGoPrevious)
            send_data("previous");
    }
    void pause() {
        if (player.CanPause)
            send_data("pause");
    }
    void play_pause() {
        if (player.CanPlay && player.CanPause)
            send_data("playPause");
    }
    void stop() {
        if (player.CanControl)
            send_data("stop");
    }
    void play() {
        if (player.CanPlay)
            send_data("play");
    }
    void seek(int64 offset) {
        var new_position = player.Position + offset;
        if (new_position >= player.length) {
            next();
            return;
        }
        set_position(null, new_position >= 0 ? new_position : 0);
    }
    void set_position(ObjectPath? track_id, int64 position) {
        if (position < 0 || position > player.length)
            return;
        var payload = new Json.Object();
        payload.set_double_member("position", position / 1000.0 / 1000.0);
        send_data("setPosition", payload);
    }

    public void handle_data(string event, Json.Object json) {
        debug("Event: %s.", event);
        switch (event) {
        case "gone":
            // TODO: unregister_service()
            player.set_playback_status("Stopped");
            break;
        case "playing":
            player.set_playback_status("Playing");
            string page_title = json.get_string_member("pageTitle");
            string tab_title  = json.get_string_member("tabTitle");
            string url        = json.get_string_member("url");
            string media_src  = json.get_string_member("mediaSrc");
            string poster_url = json.get_string_member("poster");
            // TODO: Metadata
            double old_volume = player.Volume;
            player.muted  = json.get_boolean_member("muted");
            double volume = json.get_double_member("volume");
            // both doubles are calculated the same way and coherent.
            if (volume != old_volume)
                player.Volume = volume;
            player.length = (int64)(json.get_double_member("duration") * 1000000);
            player.Position = (int64)(json.get_double_member("currentTime") * 1000000);
            double playback_rate = json.get_double_member("playbackRate");
            if (player.Rate != playback_rate)
                player.Rate = playback_rate;
            // Do not overwrite "Playlist" with "Track".
            bool loop = json.get_boolean_member("loop");
            if (player.LoopStatus == "None") {
                if (loop)
                    player.LoopStatus = "Track";
            } else if (!loop)
                player.LoopStatus = "None";
            bool fullscreen = json.get_boolean_member("fullscreen");
            if (mp.Fullscreen != fullscreen)
                mp.Fullscreen = fullscreen;
            bool can_set_fullscreen = json.get_boolean_member("canSetFullscreen");
            if (mp.CanSetFullscreen != can_set_fullscreen)
                mp.set_can_set_fullscreen(can_set_fullscreen);
            player.process_metadata(json.get_object_member("metadata"));
            player.process_callbacks(json.get_array_member("callbacks"));
            break;
        case "waiting":
        case "paused":  player.set_playback_status("Paused");  break;
        case "stopped": player.set_playback_status("Stopped"); break;
        case "canplay": player.set_playback_status("Playing"); break;
        case "duration":
            player.length = (int64)(json.get_double_member("duration") * 1000000);
            break;
        case "timeupdate":
            // FIXME: shall be not signalling to avoid excess dbus traffic
            // media controller asks for this property once when it opens
            player.Position = (int64)(json.get_double_member("currentTime") * 1000000);
            break;
        case "ratechange":
            player.Rate = json.has_member("playbackRate")
                        ? json.get_double_member("playbackRate") : 1.0;
            break;
        case "seeking":
        case "seeked":
            player.Position = (int64)(json.get_double_member("currentTime") * 1000000);
            break;
        case "volumechange":
            player.muted  = json.has_member("muted")
                          ? json.get_boolean_member("muted") : false;
            player.Volume = json.has_member("volume")
                          ? json.get_double_member("volume") : 1.0;
            break;
        case "metadata":
            player.process_metadata(json.get_object_member("metadata"));
            break;
        case "callbacks":
            player.process_callbacks(json.get_array_member("callbacks"));
            break;
        case "titlechange":
            string page_title = json.get_string_member("pageTitle");
            // TODO: Title
            break;
        case "fullscreenchange":
            bool fullscreen = json.get_boolean_member("fullscreen");
            if (mp.Fullscreen != fullscreen)
                mp.Fullscreen = fullscreen;
            break;
        default:
            debug("Unknown event: %s.", event);
            break;
        }
    }

}

