project('plasma-browser-integration-host', ['c', 'vala'],
          version: '0.10',
    meson_version: '>= 0.50.0',
  default_options: [ 'warning_level=2',
                   ],
)

host_exe_name = meson.project_name()

subdir('host')

conf_data = configuration_data()
conf_data.set('host_exe', get_option('prefix')/get_option('bindir')/host_exe_name)

firefox_json = 'org.kde.plasma.firefox_integration.json'
configure_file(
          input: firefox_json + '.in',
         output: firefox_json,
  configuration: conf_data,
)

chrome_json = 'org.kde.plasma.chrome_integration.json'
configure_file(
          input: chrome_json + '.in',
         output: chrome_json,
  configuration: conf_data,
)

browser_json = 'org.kde.plasma.browser_integration.json'

buildtype = get_option('buildtype')
if buildtype == 'release' or buildtype == 'plain'

	install_data(
	      sources: meson.build_root() / firefox_json,
	       rename: browser_json,
	  install_dir: '/usr/lib64/mozilla/native-messaging-hosts',
	)
	install_data(
	      sources: meson.build_root() / chrome_json,
	       rename: browser_json,
	  install_dir: '/etc/chromium/native-messaging-hosts',
	)
	install_data(
	      sources: meson.build_root() / chrome_json,
	       rename: browser_json,
	  install_dir: '/etc/opt/chrome/native-messaging-hosts',
	)

endif

