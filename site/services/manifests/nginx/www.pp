class services::nginx::www (
    Array   $versions = $services::nginx::params::versions,
    Hash    $projects = $services::nginx::params::projects,
    String  $domain   = $services::nginx::params::domain,
    Boolean $certbot  = $services::nginx::params::certbot
) {
    info("Initialize")

    # Validity of existing certs in /etc/nginx/ssl (custom fact, 30-day margin)
    $ssl_certs = pick($facts['nginx_ssl_certs'], {})

    if $certbot {
        info("certbot mode enabled — skipping self-signed root certificate for $domain")
        require services::certbot
    } elsif $ssl_certs[$domain] {
        info("[domain] Certificate for $domain is still valid - skipping generation")
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

        # Project "www" is served from the root domain: <name>.<domain> instead of <name>.www.<domain>
        $base = $project ? {
            'www'   => $domain,
            default => "$project.$domain",
        }

        # nginx variable names allow only [A-Za-z0-9_]: sev-auto -> $sev_auto_cors_orig
        $cors = regsubst($project, '[^A-Za-z0-9_]', '_', 'G')

        file { "/etc/nginx/$project.d":
            ensure  => 'directory',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            require => [
                Package['nginx']
            ]
        }

        # map is valid only in http context, which includes conf.d/*.conf
        info("[$project:$name] add CORS for subdomains in /etc/nginx/conf.d/cors-$project.conf")
        file { "/etc/nginx/conf.d/cors-$project.conf":
            notify  => Service["nginx"],
            ensure  => file,
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            content => epp("services/nginx/project.d/00-cors.conf.epp", {
                'cors'    => $cors,
                'base'    => $base
            }),
            require => [
                File["/etc/nginx/conf.d"]
            ]
        }

        file { "/etc/nginx/$project.d/00-cors.conf":
            ensure  => absent,
        }

        info("[domain] Generate self signed certificate - $base")
        if $certbot {
            info("certbot mode enabled — wildcard cert for *.$base is managed manually via DNS-01 challenge")
            # Cert is obtained manually:
            # certbot certonly --manual --rsa-key-size 4096 -d *.$base -d $base --agree-tos --preferred-challenges dns-01
        } else {
            if $ssl_certs["$base"] {
                info("[domain] Certificate for $base is still valid - skipping generation")
                $cert_require = []
            } elsif $base == $domain {
                info("[domain] Project $project uses root certificate $domain")
                $cert_require = [Openssl::Certificate::X509[$domain]]
            } else {
                openssl::certificate::x509 { "$base":
                  ensure       => present,
                  country      => 'DE',
                  organization => "*.$base Inc",
                  commonname   => "*.$base",
                  state        => 'Localhost',
                  locality     => 'VM',
                  unit         => 'Developer instance',
                  altnames     => ["*.$base", "$base"],
                  email        => "admin@$base",
                  days         => 3650,
                  base_dir     => '/etc/nginx/ssl',
                  owner        => 'root',
                  group        => 'root',
                }
                $cert_require = [Openssl::Certificate::X509["$base"]]
            }

            file { "/usr/local/share/ca-certificates/$base.crt":
              ensure  => present,
              source  => "/etc/nginx/ssl/$base.crt",
              owner   => 'root',
              group   => 'root',
              mode    => '0644',
              require => $cert_require,
            }
        }

        $list.filter |$item| { $item['tpl'] == 'proxy' or $item['tpl'] == 'docker' }.each |Integer $index, Hash $sub| {
            $name = $sub['name'];
            $configTpl = $sub['tpl'];

            info("[$project:$name] Sub porject directories /var/www/$name.$base")
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
                    'base'    => $base,
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
                  'base'    => $base,
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
            host { "$name.$base":
              ensure  => 'present',
              ip      => '127.0.0.1',
              comment => "/var/www/$name.$base/",
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
            host { "$name.$base":
              ensure  => 'present',
              ip      => '127.0.0.1',
              comment => "/var/www/$name.$base/",
            }
        }

        $list.filter |$item| { $item['tpl'] != 'proxy' and $item['tpl'] != 'docker' and $item['tpl'] != 'stream' }.each |Integer $index, Hash $sub| {
            $name = $sub['name'];
            $configTpl = $sub['tpl'];

            info("[$project:$name] Sub porject directories /var/www/$name.$base")
            if $configTpl == 'magento' {
                $root = "/var/www/$name.$base/pub"
            }
            elsif $configTpl == 'symfony' {
                $root = "/var/www/$name.$base/public"
            }
            elsif $configTpl == 'phpbb' {
                $root = "/var/www/$name.$base"
            }
            else {
                $root = "/var/www/$name.$base/public"
            }

            file { "/var/www/$name.$base" :
                ensure  => 'directory',
                owner   => 'www-data',
                group   => 'www-data',
                mode    => '0777',
                require => [
                    Package['nginx']
                ]
            }

            if $root != "/var/www/$name.$base" {
                info("[$project:$name] add root directory: $root")
                file { "$root":
                  ensure  => 'directory',
                  owner   => 'www-data',
                  group   => 'www-data',
                  mode    => '0777',
                  require => [
                      File["/var/www/$name.$base"]
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
                    'base'    => $base,
                    'gzip'    => true,
                    'perf'    => true,
                    'static'  => true,
                }),
                require => [
                    File["/var/www/$name.$base"],
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
                  'base'    => $base,
                  'cors'    => $cors
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
            host { "$name.$base":
              ensure  => 'present',
              ip      => '127.0.0.1',
              comment => "/var/www/$name.$base/",
            }
        }

        if $certbot {
            file { "/etc/nginx/$project.d/ssl.conf":
                ensure  => file,
                content => epp('services/nginx/vhost/ssl-certbot.conf.epp', {
                    'base'    => $base,
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
                require => [File["/etc/nginx/$project.d"]] + $cert_require,
            }
        }
    }
}
