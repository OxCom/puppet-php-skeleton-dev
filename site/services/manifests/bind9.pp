class services::bind9 (
  String $zone  = $services::bind9::params::zone,
  Array $dns = $services::bind9::params::dns
) inherits services::bind9::params {
  info("Initialize")

  # http://xgu.ru/wiki/%D0%9D%D0%B0%D1%81%D1%82%D1%80%D0%BE%D0%B9%D0%BA%D0%B0_DNS-%D1%81%D0%B5%D1%80%D0%B2%D0%B5%D1%80%D0%B0_BIND
  include services::bind9::package

  file { "/var/cache/bind":
    ensure  => 'directory',
    owner   => 'root',
    group   => 'bind',
    mode    => '0775',
    require => [
      Package["bind9"]
    ]
  }

  # https://puppet.com/docs/facter/3.6/core_facts.html#ipaddress
  file { '/etc/bind/named.conf.options':
    ensure  => file,
    content => template('services/bind9/options.erb'),
    notify  => Service["bind9"],
    require => [
      File["/var/cache/bind"],
      Package["bind9"]
    ]
  }

  include services::bind9::zone

  exec {"update-resolve-conf":
    command => 'resolvconf -u',
    provider => shell,
    require => [
      Class['services::bind9::zone'],
      Class['services::bind9::package']
    ]
  }
}