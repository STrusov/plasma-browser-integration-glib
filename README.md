# Plasma Browser Integration Host

This project aims to support [Plasma Browser Integration](https://community.kde.org/Plasma/Browser_Integration)
plugin with others (GTK-based) Desktop Environments.

## How to use
First of all install the corresponding browser plugin:
* [Chromium-based](https://chrome.google.com/webstore/detail/plasma-integration/cimiefiiaegbelhefglklhhakcgmhkai)
* [Firefox](https://addons.mozilla.org/ru/firefox/addon/plasma-integration/)

Please note Chromium has built-in partial MPRIS support, see #hardware-media-key-handling and #enable-media-session-service about://flags options. It should be disabled to do not interfere.

### Gnome
Install [Mpris Indicator Button](https://extensions.gnome.org/extension/1379/mpris-indicator-button/) for 3.36+ (3.34 should work too, IIRC) or [Media Player Indicator](https://extensions.gnome.org/extension/55/media-player-indicator/) for v3.32 (not tested).
![](https://forum.altlinux.org/index.php?action=dlattach;topic=44009.0;attach=26669;image)

### i3/Sway
To support Play/Pause, add to the configuration file:

    bindsym XF86AudioPlay exec dbus-send --type=method_call --dest=org.mpris.MediaPlayer2.plasma-browser-integration  /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause
Take a look at [MediaPlayer2.Player interface](https://specifications.freedesktop.org/mpris-spec/latest/Player_Interface.html) for possible methods (however not all are supported).

### Other DEs
Bind the `bus-send` command given above to a hotkey. If some MPRIS controller extension exists for that DE, it should work. Please let me know if you find one.

## Building and installing from the source code

Make sure development files for the fillowing libraries are provided:
* glib-2.0
* gobject-2.0
* gio-2.0
* json-glib-1.0

To build from git:

    $ git clone https://github.com/STrusov/plasma-browser-integration-glib.git
    $ cd plasma-browser-integration-glib
    $ meson --prefix=/usr build
    $ ninja -C build
    $ sudo ninja -C build install
    
## Any issues?

Not all web-sites provide good mediaplayers. Check [Video / Media Session Sample](https://googlechrome.github.io/samples/media-session/video.html).
