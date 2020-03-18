class services::nginx::www (
    Array $versions = $services::nginx::params::versions,
    Hash $projects  = $services::nginx::params::projects,
    String $domain  = $services::nginx::params::domain
) {
    info("Initialize")

    $projects.each |String $project, Array $list| {
        info("Initialize project $project")
        file { "/etc/nginx/$project.d":
            ensure  => 'directory',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            require => [
                Package['nginx-full']
            ]
        }

        $list.each |Integer $index, Hash $sub| {
            $name = $sub['name'];
            info("[$project:$name] Sub porject directories /var/www/$name.$project.$domain")

            file { [
                "/var/www/$name.$project.$domain",
                "/var/www/$name.$project.$domain/public"
            ]:
                ensure  => 'directory',
                owner   => 'www-data',
                group   => 'www-data',
                mode    => '0777',
                require => [
                    Package['nginx-full']
                ]
            }

            info("[$project:$name] set vHost config in /etc/nginx/sites-available/$name.$project.conf")
            file { "/etc/nginx/sites-available/$name.$project.conf":
                notify  => Service["nginx"],
                ensure  => file,
                owner   => 'root',
                group   => 'root',
                mode    => '0644',
                content => epp('services/nginx/vhost.conf.epp', {
                    'name'    => $name,
                    'php'     => $sub['php'],
                    'project' => $project,
                    'domain'  => $domain
                }),
                require => [
                    File["/var/www/$name.$project.$domain/public"]
                ]
            }

            info("[$project:$name] set host config in /etc/nginx/$project.d/$name.conf")
            file { "/etc/nginx/$project.d/$name.conf":
                notify  => Service["nginx"],
                ensure  => file,
                owner   => 'root',
                group   => 'root',
                mode    => '0644',
                content => epp('services/nginx/php-server.conf.epp', {
                    'name'    => $name,
                    'php'     => $sub['php'],
                    'project' => $project,
                    'domain'  => $domain
                }),
                require => [
                    File["/etc/nginx/$project.d"]
                ]
            }

            info("[$project:$name] enable vHost")
            file { "/etc/nginx/sites-enabled/$name.$project.conf":
                ensure  => 'link',
                target  => "/etc/nginx/sites-available/$name.$project.conf",
                require => [
                    File["/etc/nginx/sites-available/$name.$project.conf"]
                ]
            }

            info("[$project:$name] add host to /etc/hosts")
            host { "$name.$project.$domain":
                ip      => '127.0.0.1',
                comment => "/var/www/$name.$project.$domain/",
            }
        }

        info("[$project] Generate self signed certificate")
        file { "/etc/nginx/ssl":
            ensure  => 'directory',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            require => [
                Package['nginx-full']
            ]
        }

        openssl::certificate::x509 { "$project.$domain":
            ensure       => present,
            country      => 'CH',
            organization => "$project.$domain Inc",
            commonname   => "*.$project.$domain",
            state        => 'Dummy',
            locality     => 'VM',
            unit         => 'Developer instance',
            email        => "admin@$project.$domain",
            days         => 3650,
            base_dir     => '/etc/nginx/ssl',
            owner        => 'root',
            group        => 'root',
        }

        file { "/etc/nginx/$project.d/ssl.conf":
            ensure  => file,
            content => template('services/nginx/ssl.conf.erb'),
            notify  => Service["nginx"],
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            require => [
                File["/etc/nginx/$project.d"]
            ]
        }
    }

    info("Generate snippets")
    file { '/etc/nginx/snippets':
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => [
            Package['nginx-full']
        ]
    }

    info("[Snippet]: SSL")
    file { '/etc/nginx/snippets/ssl.conf':
        ensure  => file,
        content => template('services/nginx/snippet/ssl.conf.erb'),
        notify  => Service["nginx"],
        owner   => 'root',
        group   => 'root',
        require => [
            File['/etc/nginx/snippets']
        ]
    }

    info("[Snippet]: GZip")
    file { '/etc/nginx/snippets/gzip.conf':
        ensure  => file,
        content => template('services/nginx/snippet/gzip.conf.erb'),
        notify  => Service["nginx"],
        owner   => 'root',
        group   => 'root',
        require => [
            File['/etc/nginx/snippets']
        ]
    }

    info("[Snippet]: Static")
    file { '/etc/nginx/snippets/static.conf':
        ensure  => file,
        content => template('services/nginx/snippet/static.conf.erb'),
        notify  => Service["nginx"],
        owner   => 'root',
        group   => 'root',
        require => [
            File['/etc/nginx/snippets']
        ]
    }
}
