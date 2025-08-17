#!/bin/bash
set -x
#curl -s https://raw.githubusercontent.com/jrporto2/odoo-17-docker-compose/refs/heads/master/run.sh | sudo bash -s odoo-one 10017 20017 password
DESTINATION=$1
PORT=$2
CHAT=$3
MASTERPASSWORD=${4:-adminpasswd}
# Clone Odoo directory
git clone --depth=1 https://github.com/jrporto2/odoo-17-docker-compose.git $DESTINATION
rm -rf $DESTINATION/.git
#mkdir -p $DESTINATION/datadrive/nginx/certs
#mkdir -p $DESTINATION/datadrive/postgres/db
# Change ownership to current user and set restrictive permissions for security
sudo chown -R $USER:$USER $DESTINATION
sudo chmod -R 700 $DESTINATION  # Only the user has access
#sudo chown -R 102:102 $DESTINATION/datadrive/odoo      # nginx usa UID/GID 101
#sudo chown -R 101:101 $DESTINATION/datadrive/nginx    # nginx usa UID/GID 101
#sudo chown -R 999:999 $DESTINATION/datadrive/postgres # PostgreSQL usa UID/GID 999
sudo scp /etc/ssl/certs/odoo-selfsigned.crt $DESTINATION/datadrive/nginx/certs/odoo-selfsigned.crt
sudo scp /etc/ssl/private/odoo-selfsigned.key $DESTINATION/datadrive/nginx/certs/odoo-selfsigned.key
sudo chmod +x $DESTINATION/entrypoint.sh
# Check if running on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "Running on macOS. Skipping inotify configuration."
else
  # System configuration
  if grep -qF "fs.inotify.max_user_watches" /etc/sysctl.conf; then
    echo $(grep -F "fs.inotify.max_user_watches" /etc/sysctl.conf)
  else
    echo "fs.inotify.max_user_watches = 524288" | sudo tee -a /etc/sysctl.conf
  fi
  sudo sysctl -p
fi
# Set ports in .env file
# Update docker-compose configuration
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS sed syntax
  sed -i '' 's/10017/'$PORT'/g' $DESTINATION/.env
  sed -i '' 's/20017/'$CHAT'/g' $DESTINATION/.env
else
  # Linux sed syntax
  sed -i 's/10017/'$PORT'/g' $DESTINATION/.env
  sed -i 's/20017/'$CHAT'/g' $DESTINATION/.env
  sed -i 's/adminpasswd/'$MASTERPASSWORD'/g' $DESTINATION/datadrive/odoo/etc/odoo.conf 
fi

# Set file and directory permissions after installation
find $DESTINATION -type f -exec chmod 644 {} \;
find $DESTINATION -type d -exec chmod 755 {} \;

# Run Odoo
docker compose -f $DESTINATION/docker-compose.yml up -d

echo "Odoo started at http://localhost:$PORT | Master Password: $MASTERPASSWORD | Live chat port: $CHAT"
