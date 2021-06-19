class services::nginx::www (
    Array $versions = $services::nginx::params::versions,
    Hash $projects  = $services::nginx::params::projects,
    String $domain  = $services::nginx::params::domain
) {
    info("Initialize")

    file { "/etc/nginx/ssl":
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => [
            Package['nginx-full']
        ]
    }

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

        info("[$project:$name] add CORS for subdomains in /etc/nginx/$project.d/00-cors.conf")
        file { "/etc/nginx/$project.d/00-cors.conf":
            notify  => Service["nginx"],
            ensure  => file,
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            content => epp("services/nginx/project.d/00-cors.conf.epp", {
                'name'    => $name,
                'project' => $project,
                'domain'  => $domain
            }),
            require => [
                File["/etc/nginx/$project.d"]
            ]
        }

        $list.each |Integer $index, Hash $sub| {
            $name = $sub['name'];
            $configTpl = $sub['tpl'];

            info("[$project:$name] Sub porject directories /var/www/$name.$project.$domain")
            if $configTpl == 'magento' {
                $root = "/var/www/$name.$project.$domain/pub"
            }
            elsif $configTpl == 'symfony' {
                $root = "/var/www/$name.$project.$domain/public"
            }
            elsif $configTpl == 'phpbb' {
                $root = "/var/www/$name.$project.$domain"
            }
            else {
                $root = "/var/www/$name.$project.$domain/public"
            }

            file { "/var/www/$name.$project.$domain" :
                ensure  => 'directory',
                owner   => 'www-data',
                group   => 'www-data',
                mode    => '0777',
                require => [
                    Package['nginx-full']
                ]
            }

            if $root != "/var/www/$name.$project.$domain" {
                info("[$project:$name] add root directory: $root")
                file { "$root" :
                    ensure  => 'directory',
                    owner   => 'www-data',
                    group   => 'www-data',
                    mode    => '0777',
                    require => [
                        File["/var/www/$name.$project.$domain"]
                    ]
                }
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
                    File["/var/www/$name.$project.$domain"]
                ]
            }

            info("[$project:$name] set host config in /etc/nginx/$project.d/$name.conf")
            file { "/etc/nginx/$project.d/$name.conf":
                notify  => Service["nginx"],
                ensure  => file,
                owner   => 'root',
                group   => 'root',
                mode    => '0644',
                content => epp("services/nginx/project.d/php-$configTpl.conf.epp", {
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
            content => template('services/nginx/vhost/ssl.conf.erb'),
            notify  => Service["nginx"],
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            require => [
                File["/etc/nginx/$project.d"]
            ]
        }

        # copy cert here /usr/local/share/ca-certificates
    }
}
