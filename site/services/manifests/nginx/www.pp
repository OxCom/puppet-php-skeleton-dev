class services::nginx::www (
    Array   $versions = $services::nginx::params::versions,
    Hash    $projects = $services::nginx::params::projects,
    String  $domain   = $services::nginx::params::domain,
    Boolean $certbot  = $services::nginx::params::certbot
) {
    info("Initialize")

    if $certbot {
        info("certbot mode enabled — skipping self-signed root certificate for $domain")
        require services::certbot
    } else {
        info("[domain] Generate self signed certificate - $domain")
        openssl::certificate::x509 { "$domain":
          ensure       => present,
          country      => 'DE',
          organization => "*.$domain Inc",
          commonname   => "*.$domain",
          state        => 'Localhost',
          locality     => 'VM',
          unit         => 'Developer instance',
          altnames     => ["*.$domain", "www.$domain", "$domain"],
          email        => "admin@$domain",
          days         => 3650,
          base_dir     => '/etc/nginx/ssl',
          owner        => 'root',
          group        => 'root',
        }
    }

    info("Add streams folder")
    file { "/etc/nginx/streams":
      ensure  => 'directory',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      require => [
        Package['nginx']
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
                Package['nginx']
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

        info("[domain] Generate self signed certificate - $project.$domain")
        if $certbot {
            info("certbot mode enabled — wildcard cert for *.$project.$domain is managed manually via DNS-01 challenge")
            # Cert is obtained manually:
            # certbot certonly --manual --rsa-key-size 4096 -d *.$project.$domain -d $project.$domain --agree-tos --preferred-challenges dns-01
        } else {
            openssl::certificate::x509 { "$project.$domain":
              ensure       => present,
              country      => 'DE',
              organization => "*.$project.$domain Inc",
              commonname   => "*.$project.$domain",
              state        => 'Localhost',
              locality     => 'VM',
              unit         => 'Developer instance',
              altnames     => ["*.$project.$domain", "$project.$domain"],
              email        => "admin@$project.$domain",
              days         => 3650,
              base_dir     => '/etc/nginx/ssl',
              owner        => 'root',
              group        => 'root',
            }

            file { "/usr/local/share/ca-certificates/$project.$domain.crt":
              ensure  => present,
              source  => "/etc/nginx/ssl/$project.$domain.crt",
              owner   => 'root',
              group   => 'root',
              mode    => '0644',
              require => [
                  Openssl::Certificate::X509["$project.$domain"]
              ]
            }
        }

        # Handle proxy and docker templates
        $list.filter |$item| { $item['tpl'] == 'proxy' or $item['tpl'] == 'docker' }.each |Integer $index, Hash $sub| {
            $name = $sub['name'];
            $configTpl = $sub['tpl'];

            info("[$project:$name] Sub porject directories /var/www/$name.$project.$domain")
            info("[$project:$name] configured as $configTpl (no project directory required)")

            info("[$project:$name] set vHost config in /etc/nginx/sites-available/$name.$project.conf")
            file { "/etc/nginx/sites-available/$name.$project.conf":
                notify  => Service["nginx"],
                ensure  => file,
                owner   => 'root',
                group   => 'root',
                mode    => '0644',
                content => epp('services/nginx/vhost.conf.epp', {
                    'name'    => $name,
                    'project' => $project,
                    'domain'  => $domain,
                    'gzip'    => false,
                    'perf'    => false,
                    'static'  => false,
                }),
                require => [
                    Package['nginx'],
                    File['/etc/nginx/sites-available'],
                ]
            }

            info("[$project:$name] set host config in /etc/nginx/$project.d/$name.conf")
            $wss = pick($sub['ws'], [])

            file { "/etc/nginx/$project.d/$name.conf":
                notify  => Service["nginx"],
                ensure  => file,
                owner   => 'root',
                group   => 'root',
                mode    => '0644',
                content => epp("services/nginx/project.d/proxy.conf.epp", {
                  'name'    => $name,
                  'port'    => $sub['port'],
                  'docker'  => $configTpl == 'docker',
                  'project' => $project,
                  'domain'  => $domain,
                  'wss'     => $wss,
                }),
                require => [
                  File["/etc/nginx/$project.d"],
                ]
            }

            $streams = pick($sub['streams'], [])

            info("[$project:$name] set streams config in /etc/nginx/streams/$project.$name.conf")
            if empty($streams) {
              file { "/etc/nginx/streams/$project.$name.conf":
                notify  => Service["nginx"],
                ensure  => absent,
              }
            } else {
              file { "/etc/nginx/streams/$project.$name.conf":
                notify  => Service["nginx"],
                ensure  => file,
                owner   => 'root',
                group   => 'root',
                mode    => '0644',
                content => epp("services/nginx/project.d/streams.conf.epp", {
                  'name'    => $name,
                  'streams' => $streams,
                }),
                require => [
                  File["/etc/nginx/streams"],
                  File["/etc/nginx/$project.d"],
                ]
              }
            }

            info("[$project:$name] enable vHost")
            file { "/etc/nginx/sites-enabled/$name.$project.conf":
              ensure  => 'link',
              target  => "/etc/nginx/sites-available/$name.$project.conf",
              require => [
                File["/etc/nginx/sites-available/$name.$project.conf"],
              ]
            }

            info("[$project:$name] add host to /etc/hosts")
            host { "$name.$project.$domain":
              ensure  => 'present',
              ip      => '127.0.0.1',
              comment => "/var/www/$name.$project.$domain/",
            }
        }

        $list.filter |$item| { $item['tpl'] == 'stream' }.each |Integer $index, Hash $sub| {
            $name = $sub['name'];
            $configTpl = 'stream';

            info("[$project:$name] set stream config in /etc/nginx/streams/$project.$name.conf")

            if empty($sub['stream']) {
              file { "/etc/nginx/streams/$project.$name.conf":
                notify  => Service["nginx"],
                ensure  => absent,
              }
            } else {
              file { "/etc/nginx/streams/$project.$name.conf":
                notify  => Service["nginx"],
                ensure  => file,
                owner   => 'root',
                group   => 'root',
                mode    => '0644',
                content => epp("services/nginx/project.d/stream.conf.epp", {
                  'name'   => $name,
                  'port'   => $sub['port'],
                  'target' => $sub['target'],
                }),
                require => [
                  File["/etc/nginx/streams"],
                  File["/etc/nginx/$project.d"],
                ]
              }
            }

            info("[$project:$name] add host to /etc/hosts")
            host { "$name.$project.$domain":
              ensure  => 'present',
              ip      => '127.0.0.1',
              comment => "/var/www/$name.$project.$domain/",
            }
        }

        $list.filter |$item| { $item['tpl'] != 'proxy' and $item['tpl'] != 'docker' and $item['tpl'] != 'stream' }.each |Integer $index, Hash $sub| {
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
                    Package['nginx']
                ]
            }

            if $root != "/var/www/$name.$project.$domain" {
                info("[$project:$name] add root directory: $root")
                file { "$root":
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
                    'project' => $project,
                    'domain'  => $domain,
                    'gzip'    => true,
                    'perf'    => true,
                    'static'  => true,
                }),
                require => [
                    File["/var/www/$name.$project.$domain"],
                    File['/etc/nginx/sites-available'],
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
                  File["/etc/nginx/$project.d"],
              ]
            }

            info("[$project:$name] enable vHost")
            file { "/etc/nginx/sites-enabled/$name.$project.conf":
              ensure  => 'link',
              target  => "/etc/nginx/sites-available/$name.$project.conf",
              require => [
                File["/etc/nginx/sites-available/$name.$project.conf"],
              ]
            }

            info("[$project:$name] add host to /etc/hosts")
            host { "$name.$project.$domain":
              ensure  => 'present',
              ip      => '127.0.0.1',
              comment => "/var/www/$name.$project.$domain/",
            }
        }

        if $certbot {
            file { "/etc/nginx/$project.d/ssl.conf":
                ensure  => file,
                content => epp('services/nginx/vhost/ssl-certbot.conf.epp', {
                    'project' => $project,
                    'domain'  => $domain,
                }),
                notify  => Service["nginx"],
                owner   => 'root',
                group   => 'root',
                mode    => '0644',
                require => [
                    File["/etc/nginx/$project.d"],
                ]
            }
        } else {
            file { "/etc/nginx/$project.d/ssl.conf":
                ensure  => file,
                content => template('services/nginx/vhost/ssl.conf.erb'),
                notify  => Service["nginx"],
                owner   => 'root',
                group   => 'root',
                mode    => '0644',
                require => [
                    File["/etc/nginx/$project.d"],
                    Openssl::Certificate::X509["$project.$domain"]
                ]
            }
        }
    }
}
