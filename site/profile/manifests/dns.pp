class profile::dns {
  $dns = lookup('bind9.dns', Array, 'first', [])
  $zone = lookup('bind9.zone', String, 'first', $::domain)

  class { "services::bind9":
    zone => $zone,
    dns  => $dns
  }
}
