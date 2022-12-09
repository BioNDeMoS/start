#!/bin/bash

# Apply config file
config_file="/data/config.conf"

# Set password of biondemos user
HASHED_PASSWORD=$(grep HASHED_PASSWORD $config_file | cut -d '=' -f2)
if [ -n "$HASHED_PASSWORD" ]; then
  echo biondemos:$HASHED_PASSWORD | sudo chpasswd -e
fi

# Register Wifi
WPA_SSID=$(grep WPA_SSID $config_file | cut -d '=' -f2)
WPA_PASSWORD=$(grep WPA_PASSWORD $config_file | cut -d '=' -f2)
wpa_passphrase "${WPA_SSID}" "${WPA_PASSWORD}" | tee -a "/etc/wpa_supplicant/wpa_supplicant.conf"

# Generate SSH Key
if [ -f /config/autossh/id_ed25519 ]; then
  ssh-keygen -N "" -f /config/autossh/id_ed25519 -t ed25519 -C "rpi_$(grep -i serial /proc/cpuinfo | cut -d : -f2 | cut -c10-)" <<<y
fi
cp /config/autossh/id_ed25519.pub /data/id_ed25519.pub


# Clone the config repository
repo_url=$(grep REPO_URL $config_file | cut -d '=' -f2)
target_dir="/config"
if [ ! -d "$target_dir" ]; then
  # Clone the repository if the target directory does not exist
  git clone "$repo_url" "$target_dir"
else
  # Pull the latest changes from the repository if the target directory exists
  cd "$target_dir"
  git pull --rebase
fi

# Set permission for node-red
chown -R 1000:1000 /config/node-red

# Start docker containers
cd /config/docker
docker compose up -d --build --pull always
