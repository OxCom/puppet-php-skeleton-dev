class services::npm {
    info("Initialize")

    # --- Corporate CA workaround ---
    # puppet/nodejs uses apt::keyring { source => 'https://deb.nodesource.com/...' }
    # internally.  Puppet's file provider always re-checks the HTTPS source for metadata
    # even when the file already exists, so the corporate MITM proxy breaks it.
    # Fix: download the key with system wget (which honours the OS CA bundle already
    # containing Crytek-CA-SelfSigned) to a local temp file, then use a resource collector
    # to redirect the inner File resource's source away from the HTTPS URL.
    exec { 'apt-keyring-nodesource':
        command => '/usr/bin/wget -q "https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key" -O /tmp/puppet-nodesource.asc',
        creates => '/tmp/puppet-nodesource.asc',
    }

    # Intercept the File resource that apt::keyring[nodesource] creates inside the
    # nodejs module and point its source at the locally downloaded copy.
    File <| title == '/etc/apt/keyrings/nodesource-repo.gpg.key.asc' |> {
        source  => '/tmp/puppet-nodesource.asc',
        require => Exec['apt-keyring-nodesource'],
    }

    class { 'nodejs':
      repo_version => '22',
    }
}
