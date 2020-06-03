config = configuration_data()
config.set('version', meson.project_version())
config_vala = configure_file(
          input: 'config.vala.in',
         output: 'config.vala',
  configuration: config,
)

sources = [
  config_vala,
  'abstractbrowserplugin.vala',
  'connection.vala',
  'mpris.vala',
  'main.vala',
  'pluginmanager.vala',
  'settings.vala',
]

dependencies = [
  dependency('glib-2.0'),
  dependency('gobject-2.0'),
  dependency('gio-2.0'),
  dependency('json-glib-1.0'),
  meson.get_compiler('vala').find_library('posix'),
]

executable(host_exe_name, sources,
  vala_args: '--target-glib=2.58',  dependencies: dependencies,
  install: true,
)
