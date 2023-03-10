blackbox_sources = files(
  'Application.vala',
  'CommandLine.vala',
  'main.vala',
)

subdir('widgets')
subdir('services')
subdir('utils')

conf_data = configuration_data()
conf_data.set_quoted('PROJECT_NAME', meson.project_name())
conf_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf_data.set_quoted('VERSION', meson.project_version())
conf_data.set_quoted('PREFIX', get_option('prefix'))
conf_data.set_quoted('DATADIR', join_paths (get_option('prefix'), get_option('datadir')))
conf_data.set_quoted('LOCALEDIR', join_paths (get_option('prefix'), get_option('localedir')))
conf_data.set('DEVEL', get_option('devel').to_string().to_lower())

config_header = configure_file(
            input: 'config.vala.in',
           output: 'config.vala',
    configuration: conf_data
    )

blackbox_deps = [
  dependency('gio-2.0', version: '>= 2.50'),
  dependency('gtk4', version: '>= 4.6.2'),
  # Black Box actually depends on libadwaita >= 1.2.alpha, but I'm keeping this
  # at 1.1 to make it easier for translators to work on Black Box
  dependency('libadwaita-1', version: '>= 1.1'),
  dependency('marble', version: '>= 42'),
  dependency('vte-2.91-gtk4', version: '>= 0.69.0'),
  dependency('json-glib-1.0', version: '>= 1.4.4'),
  dependency('libpcre2-8'),
  dependency('libxml-2.0', version: '>= 2.9.12'),
  dependency('librsvg-2.0', version: '>= 2.54.0'),
  dependency('graphene-gobject-1.0'),
]

# https://github.com/elementary/terminal/blob/d9620eb12331a28c658f97ac9a1bdb809aa90089/meson.build
vapi_dir = meson.current_source_dir() / 'vapi'
add_project_arguments('--vapidir=' + vapi_dir, language: 'vala')
add_project_arguments('-DPCRE2_CODE_UNIT_WIDTH=0', language: 'c')

# This is required until VTE 0.70 is out
add_project_arguments('--disable-since-check', language: 'vala')

gnome = import('gnome')

blackbox_sources += gnome.compile_resources('blackbox-resources',
  'blackbox.gresource.xml',
  c_name: 'blackbox'
)

executable('blackbox', blackbox_sources, config_header,
  vala_args: '--target-glib=2.50',  dependencies: blackbox_deps,
  install: true,
)

if get_option('devel')
  custom_target ('flatpak-exe',
                 input: 'blackbox-link-system-fonts',
                 output: ['blackbox-link-system-fonts'],
                 command: ['cp', '@INPUT@', '@OUTPUT@'],
                 install: true,
                 install_dir: 'bin')
endif
