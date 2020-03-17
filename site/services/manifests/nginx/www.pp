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
        file { "/etn/nginx/ssl":
            ensure  => 'directory',
            owner   => 'www-data',
            group   => 'www-data',
            mode    => '0775',
            require => [
                Package['nginx-full']
            ]
        }

        # openssl::certificate::x509 { "/etn/nginx/ssl/$project.$domain.crt":
        #     ensure       => present,
        #     country      => 'CH',
        #     organization => 'Example.com',
        #     commonname   => $fqdn,
        #     state        => 'Here',
        #     locality     => 'Myplace',
        #     unit         => 'MyUnit',
        #     altnames     => ['a.com', 'b.com', 'c.com'],
        #     extkeyusage  => ['serverAuth', 'clientAuth', 'any_other_option_per_openssl'],
        #     email        => 'contact@foo.com',
        #     days         => 3456,
        #     base_dir     => '/var/www/ssl',
        #     owner        => 'www-data',
        #     group        => 'www-data',
        #     password     => 'j(D$',
        #     force        => false,
        #     cnf_tpl      => 'my_module/cert.cnf.erb'
        # }
    }
}
