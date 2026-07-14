# Reports validity of self-signed certificates in /etc/nginx/ssl so Puppet can
# skip regeneration while they are still valid (30-day expiry margin).
Facter.add(:nginx_ssl_certs) do
    setcode do
        certs = {}
        Dir.glob('/etc/nginx/ssl/*.crt').each do |crt|
            name = File.basename(crt, '.crt')
            key  = "/etc/nginx/ssl/#{name}.key"
            valid = File.exist?(key) &&
                    system('openssl', 'x509', '-checkend', '2592000', '-noout', '-in', crt,
                           out: File::NULL, err: File::NULL)
            certs[name] = valid ? true : false
        end
        certs
    end
end
