#!/bin/bash

set -e

# Check if the script is being run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

systemctl stop sunshine
cp "build/sunshine" /usr/bin/sunshine
rm -rf /usr/share/sunshine
mkdir -p /usr/share/sunshine
cp -r build/assets/* /usr/share/sunshine

setcap cap_sys_admin+p $(readlink -f $(which sunshine))
