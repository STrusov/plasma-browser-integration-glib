Name: plasma-browser-integration-glib
Version: 0.10
Release: alt1

Summary: Plasma Integration browser plugin support for GTK environments.
License: MIT
Group: Graphical desktop/Gnome
Url: https://github.com/STrusov/plasma-browser-integration-glib

#Source: https://github.com/STrusov/plasma-browser-integration-glib/archive/v%version.tar.gz
Source: %name.tar.gz

Requires: libjson-glib

Conflicts: plasma5-browser-integration

BuildPreReq: meson rpm-build-vala
BuildRequires: libjson-glib-devel
BuildRequires: vala-tools

%description
%summary

%prep
%setup -n %name

%build
%meson
%meson_build

%install
%meson_install

%files
%_bindir/plasma-browser-integration-host
%config %_sysconfdir/chromium/native-messaging-hosts/org.kde.plasma.browser_integration.json
%config %_sysconfdir/opt/chrome/native-messaging-hosts/org.kde.plasma.browser_integration.json
%_libdir/mozilla/native-messaging-hosts/org.kde.plasma.browser_integration.json

%changelog
* Thu Jun 4 2020 Sergei A. Trusov <sergei.a.trusov@ya.ru> 0.10-alt1
- initial build
