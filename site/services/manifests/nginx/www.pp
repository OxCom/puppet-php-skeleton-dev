class services::nginx::www (
    Array $versions = $services::nginx::params::versions,
    Hash $projects  = $services::nginx::params::projects,
    String $domain  = $services::nginx::params::domain
) {
    info("Initialize")

    $projects.each |String $project, Array $list| {
        info("Initialize project $project")

        $list.each |Integer $index, Hash $sub| {
            # Create folder for each project
            $name = $sub['name'];
            info("[$project:$name] Sub porject directories /var/www/$name.$project.$domain")

            file { [
                "/var/www/$name.$project.$domain",
                "/var/www/$name.$project.$domain/public"
            ]:
                ensure  => 'directory',
                owner   => 'www-data',
                group   => 'www-data',
                mode    => '0775',
                require => [
                    Package['nginx-full']
                ]
            }

            info("[$project:$name] add vHost /etc/nginx/sites-available/$name.$project.conf")
            file { "/etc/nginx/sites-available/$name.$project.conf":
                notify  => Service["nginx"],
                ensure  => file,
                owner   => 'www-data',
                group   => 'www-data',
                mode    => '0755',
                content => epp('services/nginx/dummy.conf.epp', {
                    'name'    => $name,
                    'php'     => $sub['php'],
                    'project' => $project,
                    'domain'  => $domain
                }),
                require => [
                    File["/var/www/$name.$project.$domain/public"]
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

            info("[$project:$name] add host to /etc/hosts")
        }

        info("[$project] Generate self signed certificate")
        file { "/etn/nginx/ssl/$project.$domain":
            ensure  => 'directory',
            owner   => 'www-data',
            group   => 'www-data',
            mode    => '0775',
            require => [
                Package['nginx-full']
            ]
        }

        ssl_pkey { "/etn/nginx/ssl/$project.$domain/private.key":
            require => [
                File["/etn/nginx/ssl/$project.$domain"]
            ]
        }

        x509_cert { "/etn/nginx/ssl/$project.$domain/certificate.crt":
            ensure      => 'present',
            private_key => "/etn/nginx/ssl/$project.$domain/private.key",
            days        => 4536,
            require => [
                ssl_pkey["/etn/nginx/ssl/$project.$domain/private.key"]
            ],
        }
    }
}
