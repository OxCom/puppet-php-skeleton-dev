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
        file { "/etc/nginx/ssl":
            ensure  => 'directory',
            owner   => 'www-data',
            group   => 'www-data',
            mode    => '0775',
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
            owner        => 'www-data',
            group        => 'www-data',
        }

        file { '/etc/nginx/snippets/ssl.conf':
            ensure  => file,
            content => template('services/nginx/snippet-ssl.erb'),
            notify  => Service["nginx"],
            require => [
                File["/etc/nginx/conf.d/"]
            ]
        }
    }
}
