class services::git {
    info("Initialize git and GitHub CLI")

    include apt

    # gh is not shipped in default Ubuntu repos, so add the GitHub CLI apt repo.
    # Use wget (system tool / OS CA bundle) instead of Puppet's file provider so the
    # corporate self-signed proxy CA is trusted without needing to rebuild Puppet's CA store.
    exec { 'apt-keyring-githubcli':
        command => '/usr/bin/wget -q "https://cli.github.com/packages/githubcli-archive-keyring.gpg" -O /etc/apt/keyrings/githubcli-archive-keyring.gpg',
        creates => '/etc/apt/keyrings/githubcli-archive-keyring.gpg',
        require => Class['apt'],
    }

    # GitHub CLI repo uses the fixed "stable" suite, not the Ubuntu codename
    apt::source { 'github-cli':
        location     => 'https://cli.github.com/packages',
        release      => 'stable',
        repos        => 'main',
        architecture => $facts['os']['architecture'],
        keyring      => '/etc/apt/keyrings/githubcli-archive-keyring.gpg',
        include      => {
            src => false,
            deb => true,
        },
        require      => Exec['apt-keyring-githubcli'],
    }

    package { 'git':
        ensure => present,
    }

    package { 'gh':
        ensure  => present,
        require => Apt::Source['github-cli'],
    }

    Apt::Source['github-cli']
        ~> Class['apt::update']
        -> Package['gh']
}
