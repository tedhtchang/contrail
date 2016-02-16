name             'contrail'
maintainer       'Juniper Networks'
maintainer_email 'praneetb@juniper.net'
license          'All rights reserved'
description      'Installs/Configures contrail'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.9.0'

depends 'yum'
depends 'python'
depends 'openstack-common', '>= 11.5.0'
depends 'openstack-identity', '>= 11.0.0'