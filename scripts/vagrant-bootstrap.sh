#!/bin/bash

echo "[PUPPET]: ===="
wget https://raw.githubusercontent.com/OxCom/puppet-php-skeleton-dev/master/run.sh
chmod +x run.sh

echo "[PUPPET]: run"
sudo ./run.sh
