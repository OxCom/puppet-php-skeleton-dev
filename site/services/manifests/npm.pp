class services::npm {
  info("Initialize")

  # install ppa
  exec {"node-js-ppa":
    command => 'curl -sL https://deb.nodesource.com/setup_9.x | sudo -E bash -',
    provider => shell
  }

  # install package
  package {['nodejs']:
    ensure => present,
    require => Exec['node-js-ppa']
  }

  # do upgrade
  exec {"npm-update":
    command => 'npm install -g npm',
    provider => shell,
    require => Package['nodejs']
  }

  # may be: sudo n stable
}