

/** [[https://specifications.freedesktop.org/mpris-spec/latest/|MPRIS D-Bus Interface Specification]] */
class Mpris : AbstractBrowserPlugin, Object {

    public unowned string subsystem_name() { return "mpris"; }

    /** [[https://specifications.freedesktop.org/mpris-spec/latest/Media_Player.html|Specification]] */
    [DBus(name = "org.mpris.MediaPlayer2")]
    class MediaPlayer2 : Object {
        Mpris impl;
        internal const int id = 0;

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
            internal const int id = MediaPlayer2.id + 1;

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
            public  HashTable<string, Variant> Metadata {
                get; internal set; default = new HashTable<string, Variant>(str_hash, str_equal);
            }

            internal bool muted = false;
            // The following property is to be set only by DBus manager.
            // On browser event the corresponding variable shall be accessed by
            // appropriate methods sheduling PropertiesChanged notifycation manually.
            private double _volume = 1.0;
            internal double get_volume() { return _volume; }
            internal void set_volume(double vol) {
                _volume = vol;
                impl.property_changes[id]["Volume"] = Volume;
                impl.shedule_property_changes();
            }
            [CCode(notify = false)]
            public double Volume {
                get { return muted ? 0.0 : _volume; }
                private set { impl.set_volume(_volume = value); }
            }
            // If the playback progresses in a way that is inconstistant
            // with the Rate property, the Seeked signal is emited.
            [CCode(notify = false)]
            public int64 Position     { get; internal set; default = 0; }
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
                set { _length = value;  CanSeek = (value > 0); }
            }
            internal void set_playback_status(string status) {
                if (PlaybackStatus != status) {
                    PlaybackStatus = status;
                // FIXME: do we need the following notifications?
                //    impl.property_changes[1]["CanPlay"] = CanPlay;
                //    impl.property_changes[1]["CanPause"] = CanPause;
                }
            }
            internal void process_callbacks(Json.Array data) {

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
        for (var i = MediaPlayer2.id; i <= MediaPlayer2.Player.id; ++i)
            property_changes[i] = new HashTable<string, Variant>(str_hash, str_equal);
        mp.notify.connect_after(mp_property_changed);
        player.notify.connect_after(player_property_changed);
    }

    DBusConnection dbus_conn;
    HashTable<string, Variant> property_changes[2];
    uint pending = 0;

    void mp_property_changed(Object source, ParamSpec property) {
        property_changed(source, property, MediaPlayer2.id);
    }
    void player_property_changed(Object source, ParamSpec property) {
        property_changed(source, property, MediaPlayer2.Player.id);
    }
    void property_changed(Object source, ParamSpec property, int id) {
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
        default:
            if (property.name == "Metadata")
                property_changes[id][property.name] = (HashTable<string, Variant>)val;
            else
                warning("%s", property.value_type.qname().to_string());
            break;
        }
        shedule_property_changes();
    }
    void shedule_property_changes() {
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
    void set_volume(double volume) {
        var payload = new Json.Object();
        payload.set_double_member("volume", volume);
        send_data("setVolume", payload);
    }

    // (since = "1.6") get_string_member_with_default
    private static unowned string json_get_string_member(Json.Object json, string name) {
        return json.has_member(name) ? json.get_string_member(name) : "";
    }
    public void handle_data(string event, Json.Object json) {
        debug("Browser event: %s.", event);
        switch (event) {
        case "gone":
            // TODO: unregister_service()
            player.set_playback_status("Stopped");
            break;
        case "playing":
            player.set_playback_status("Playing");
            page_title = json_get_string_member(json, "pageTitle");
            tab_title  = json_get_string_member(json, "tabTitle");
            url        = json_get_string_member(json, "url");
            media_src  = json_get_string_member(json, "mediaSrc");
            string poster_url = json_get_string_member(json, "poster");
            if (this.poster_url != poster_url) {
                this.poster_url = poster_url;
                // FIXME: ? player.Metadata = metadata();
            }
            player.muted  = json.get_boolean_member("muted");
            double volume = json.get_double_member("volume");
            // both doubles are calculated the same way and coherent.
            if (volume != player.get_volume())
                player.set_volume(volume);
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
            process_metadata(json.get_object_member("metadata"));
            player.process_callbacks(json.get_array_member("callbacks"));
            break;
        case "waiting":
        case "paused":  player.set_playback_status("Paused");  break;
        case "stopped": player.set_playback_status("Stopped"); break;
        case "canplay": player.set_playback_status("Playing"); break;
        case "duration":
            int64 length = (int64)(json.get_double_member("duration") * 1000000);
            if (player.length != length) {
                player.length = length;
                player.Metadata = metadata();
            }
            break;
        case "timeupdate":
            player.Position = (int64)(json.get_double_member("currentTime") * 1000000);
            break;
        case "ratechange":
            player.Rate = json.has_member("playbackRate")
                        ? json.get_double_member("playbackRate") : 1.0;
            break;
        case "seeking":
        case "seeked":
            player.Position = (int64)(json.get_double_member("currentTime") * 1000000);
            player.Seeked(player.Position);
            break;
        case "volumechange":
            player.muted  = json.has_member("muted")
                          ? json.get_boolean_member("muted") : false;
            double volume = json.has_member("volume")
                          ? json.get_double_member("volume") : 1.0;
            player.set_volume(volume);
            break;
        case "metadata":
            process_metadata(json.get_object_member("metadata"));
            break;
        case "callbacks":
            player.process_callbacks(json.get_array_member("callbacks"));
            break;
        case "titlechange":
            string old_title = effective_title();
            page_title = json.get_string_member("pageTitle");
            if (old_title != effective_title())
                player.Metadata = metadata();
            break;
        case "fullscreenchange":
            bool fullscreen = json.get_boolean_member("fullscreen");
            if (mp.Fullscreen != fullscreen)
                mp.Fullscreen = fullscreen;
            break;
        default:
            warning("Unknown event: %s.", event);
            break;
        }
    }
    // sent by the broswer plugin in a top-level JSON structure
    string page_title = "";
    string tab_title  = "";
    string url        = "";
    string media_src  = "";
    string poster_url = "";
    // and "metadata":{   }
    string title       = "";
    string artist      = "";
    string album       = "";
    string artwork_url = "";

    unowned string effective_title() {
        return title.length > 0 ? title
             : page_title.length > 0 ? page_title
             : tab_title;
    }
    void process_metadata(Json.Object data) {
        title = json_get_string_member(data, "title");
        artist = json_get_string_member(data, "artist");
        album = json_get_string_member(data, "album");
        artwork_url = "";
        if (data.has_member("artwork")) {
            Json.Array artwork = data.get_array_member("artwork");
            int max_width = 0;
            int max_height = 0;
            artwork.foreach_element((array, idx, element_node) => {
                Json.Object item = element_node.get_object();
                if (item == null)
                    return;
                string sizes = json_get_string_member(item, "sizes");
                int width = 0;
                int height = 0;
                if (sizes.scanf("%dx%d", ref width, ref height) != 2)
                    return;
                if (width >= max_width && height >= max_height)
                    artwork_url = json_get_string_member(item, "src");
            });
        }
        player.Metadata = metadata();
    }
    HashTable<string, Variant> metadata() {
        var metadata = new HashTable<string, Variant>(str_hash, str_equal);
        metadata.insert("xesam:title", effective_title());
        if (url.length > 0)
            metadata.insert("xesam:url", url);
        if (media_src.length > 0)
            metadata.insert("kde:mediaSrc", media_src);
        if (player.length > 0)
            metadata.insert("mpris:length", player.length);
        if (artist.length > 0)
            metadata.insert("xesam:artist", artist);
        if (artwork_url.length > 0 )
            metadata.insert("mpris:artUrl", artwork_url);
        else if (poster_url.length > 0)
            metadata.insert("mpris:artUrl", poster_url);
        if (album.length > 0)
            metadata.insert("xesam:album", album);
        // TODO: when we don't have artist information use the scheme+domain as "album" (that's what Chrome on Android does)
        return metadata;
    }
}

