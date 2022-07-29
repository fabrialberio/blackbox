project('blackbox', ['c', 'vala'],
          version: '0.12.0',
    meson_version: '>= 0.50.0',
  default_options: [ 'warning_level=2',
                   ],
)

if get_option('devel')
  app_id = 'com.raggesilver.BlackBox.Devel'
else
  app_id = 'com.raggesilver.BlackBox'
endif

i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

subdir('data')
subdir('src')
subdir('po')

meson.add_install_script('build-aux/meson/postinstall.py')
