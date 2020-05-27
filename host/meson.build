sources = [
  'abstractbrowserplugin.vala',
  'connection.vala',
  'mpris.vala',
  'main.vala',
  'pluginmanager.vala',
]

dependencies = [
  dependency('glib-2.0'),
  dependency('gobject-2.0'),
  dependency('gio-2.0'),
  dependency('json-glib-1.0'),
  meson.get_compiler('vala').find_library('posix'),
]

executable('plasma-browser-integration-host', sources,
  vala_args: '--target-glib=2.58',  dependencies: dependencies,
  install: true,
)
