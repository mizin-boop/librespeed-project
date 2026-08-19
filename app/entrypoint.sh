#!/bin/sh
set -eu

: "${MODE:=frontend}"
: "${TELEMETRY:=true}"
: "${ENABLE_ID_OBFUSCATION:=true}"
: "${OBFUSCATION_SALT:=0x1234abcd}"
: "${REDACT_IP_ADDRESSES:=false}"
: "${PASSWORD:=stats-password}"
: "${GDPR_EMAIL:=admin@example.com}"
: "${DB_TYPE:=mysql}"
: "${DB_HOSTNAME:=mysql}"
: "${DB_PORT:=3306}"
: "${DB_NAME:=librespeed}"
: "${DB_USERNAME:=librespeed}"
: "${DB_PASSWORD:=librespeed}"
: "${USE_NEW_DESIGN:=true}"

if [ "$MODE" != "frontend" ]; then
  echo "ERROR: this project is prepared for MODE=frontend" >&2
  exit 1
fi

if [ ! -f /servers.json ]; then
  echo "ERROR: /servers.json is not mounted" >&2
  exit 1
fi

rm -rf /var/www/html/*

cp /opt/librespeed/*.js /var/www/html/
cp /opt/librespeed/index.html /var/www/html/
cp /opt/librespeed/index-classic.html /var/www/html/
cp /opt/librespeed/index-modern.html /var/www/html/
cp /opt/librespeed/config.json /var/www/html/
cp /opt/librespeed/design-switch.js /var/www/html/
cp /opt/librespeed/stability.html /var/www/html/
cp /opt/librespeed/favicon.ico /var/www/html/
cp /opt/librespeed/manifest.webmanifest /var/www/html/

mkdir -p /var/www/html/styling /var/www/html/javascript /var/www/html/images /var/www/html/fonts
cp -a /opt/librespeed/frontend/styling/. /var/www/html/styling/
cp -a /opt/librespeed/frontend/javascript/. /var/www/html/javascript/
cp -a /opt/librespeed/frontend/images/. /var/www/html/images/
cp -a /opt/librespeed/frontend/fonts/. /var/www/html/fonts/ 2>/dev/null || true
cp /opt/librespeed/frontend/settings.json /var/www/html/settings.json

cp /servers.json /var/www/html/server-list.json
cp /servers.json /var/www/html/servers.json

if [ "$USE_NEW_DESIGN" = "true" ]; then
  sed -i 's/"useNewDesign": false/"useNewDesign": true/' /var/www/html/config.json
fi

if [ "$TELEMETRY" = "true" ]; then
  cp -a /opt/librespeed/results /var/www/html/results
  mkdir -p /var/www/html/backend
  cp /opt/librespeed/backend/getIP_util.php /var/www/html/backend/

  sed -i 's/telemetry_level": ".*"/telemetry_level": "basic"/' /var/www/html/settings.json

  SETTINGS=/var/www/html/results/telemetry_settings.php
  sed -i "s/\$db_type = '.*'/\$db_type = '${DB_TYPE}'/" "$SETTINGS"
  sed -i "s/\$stats_password = '.*'/\$stats_password = '${PASSWORD}'/" "$SETTINGS"
  sed -i "s/\$MySql_username = '.*'/\$MySql_username = '${DB_USERNAME}'/" "$SETTINGS"
  sed -i "s/\$MySql_password = '.*'/\$MySql_password = '${DB_PASSWORD}'/" "$SETTINGS"
  sed -i "s/\$MySql_hostname = '.*'/\$MySql_hostname = '${DB_HOSTNAME}'/" "$SETTINGS"
  sed -i "s/\$MySql_databasename = '.*'/\$MySql_databasename = '${DB_NAME}'/" "$SETTINGS"
  sed -i "s/\$MySql_port = '.*'/\$MySql_port = '${DB_PORT}'/" "$SETTINGS"

  if [ "$ENABLE_ID_OBFUSCATION" = "true" ]; then
    sed -i 's/$enable_id_obfuscation = false;/$enable_id_obfuscation = true;/' "$SETTINGS"
    case "$OBFUSCATION_SALT" in
      0x[0-9a-fA-F]*)
        printf '%s\n' '<?php' "\$OBFUSCATION_SALT = ${OBFUSCATION_SALT};" > /var/www/html/results/idObfuscation_salt.php
        ;;
      *)
        echo "ERROR: OBFUSCATION_SALT must be hex, for example 0x1234abcd" >&2
        exit 1
        ;;
    esac
  fi

  if [ "$REDACT_IP_ADDRESSES" = "true" ]; then
    sed -i 's/$redact_ip_addresses = false;/$redact_ip_addresses = true;/' "$SETTINGS"
  else
    sed -i 's/$redact_ip_addresses = true;/$redact_ip_addresses = false;/' "$SETTINGS"
  fi
fi

for f in /var/www/html/index-classic.html /var/www/html/index-modern.html; do
  [ -f "$f" ] && sed -i "s/TO BE FILLED BY DEVELOPER/${GDPR_EMAIL}/g; s/PUT@YOUR_EMAIL.HERE/${GDPR_EMAIL}/g" "$f"
done

chown -R www-data:www-data /var/www/html

echo "LibreSpeed configured: MODE=${MODE}, TELEMETRY=${TELEMETRY}, DB_TYPE=${DB_TYPE}, REDACT_IP_ADDRESSES=${REDACT_IP_ADDRESSES}"
exec "$@"
