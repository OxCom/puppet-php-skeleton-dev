class services::bind9::zone (
  String $zone = $services::bind9::params::zone,
) inherits services::bind9::params {
  info("Initialize")

  $ipaddress = $::ipaddress

  # forward
  file { "/etc/bind/db.$zone":
    ensure  => file,
    content => epp("services/bind9/db.zone.epp", {
      'zone'    => $zone,
      'address' => $ipaddress
    }),
    require => [
      Package["bind9"]
    ]
  }

  # backward
  $parts = split($ipaddress, '[.]')
  $rParts = reverse($parts)
  $zParts = delete_at($rParts, 0)
  $backZone = join($zParts, '.')

  file { "/etc/bind/db.$backZone":
    ensure  => file,
    content => epp("services/bind9/db.zone.epp", {
      'zone'    => $zone,
      'address' => $::ipaddress
    }),
    require => [
      Package["bind9"]
    ]
  }

  # zone
  file { "/etc/bind/zone.d/":
    ensure  => 'directory',
    owner   => 'root',
    group   => 'bind',
    mode    => '0755',
    require => [
      Package['bind9']
    ]
  }

  file { "/etc/bind/zone.d/$zone.conf":
    ensure  => file,
    content => epp("services/bind9/zone.epp", {
      'zone' => $zone,
      'back' => $backZone
    }),
    require => [
      File["/etc/bind/db.$zone"],
      File["/etc/bind/db.$backZone"],
      File["/etc/bind/zone.d/"],
      Package["bind9"]
    ]
  }

  file_line { "zone-$zone-config":
    ensure  => present,
    path    => "/etc/bind/named.conf.local",
    line    => "include \"/etc/bind/zone.d/$zone.conf\";",
    notify  => Service["bind9"],
    require => [
      File["/etc/bind/zone.d/$zone.conf"],
      Package["bind9"]
    ]
  }

  # our DNS should be first and then all other, also it will be droped after reboot.
  file_line { "resolve-ns-config":
    ensure  => present,
    path    => "/etc/resolvconf/resolv.conf.d/head",
    line    => "nameserver ${::ipaddress}",
    require => [
      File["/etc/bind/zone.d/$zone.conf"],
      Package["bind9"]
    ]
  }
}