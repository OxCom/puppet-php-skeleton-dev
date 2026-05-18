#!/bin/bash

# --- Corporate CA workaround ---
# The company network uses a MITM proxy signed by a self-signed CA (Crytek-CA-SelfSigned).
# That CA is installed in the OS bundle (/etc/ssl/certs/ca-certificates.crt), but Puppet's
# bundled Ruby uses its own OpenSSL CA store and ignores the system bundle by default.
# Setting SSL_CERT_FILE makes Ruby's net/http (and thus Puppet's file provider) use the
# system CA bundle, so all HTTPS keyring downloads work without modifying any module.
if ! grep -q "SSL_CERT_FILE" /etc/environment 2>/dev/null; then
    echo "[SSL]: Adding SSL_CERT_FILE to /etc/environment (corporate CA workaround)"
    echo "SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt" >> /etc/environment
fi
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

echo "[PUPPET]: ===="
wget -O run.sh https://raw.githubusercontent.com/OxCom/puppet-php-skeleton-dev/master/run.sh
chmod +x run.sh

echo "[PUPPET]: run"
# -E preserves SSL_CERT_FILE so Puppet's Ruby picks up the system CA bundle
sudo -E ./run.sh
