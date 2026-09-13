#!/bin/bash

set -eu

WPDIR="/var/www/html"

source /run/secrets/wp_passwords
source /run/secrets/db_password

# ensure the PHP run dir exists for the PID file
mkdir -p /run/php

echo "waiting for mariaDB..."
# Halt execution until the MariaDB container is fully awake on the Docker network
until mariadb -h mariadb -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SELECT 1;" >/dev/null 2>&1; do
    sleep 1
done

echo "Setting up WordPress..."

if [ ! -f "$WPDIR/wp-config.php" ]; then
    echo "Downloading WordPress..."
    wget -q https://wordpress.org/latest.tar.gz -O /tmp/wordpress.tar.gz
    tar -xzf /tmp/wordpress.tar.gz -C /tmp
    rm /tmp/wordpress.tar.gz

    cp -rn /tmp/wordpress/* "$WPDIR" || true
    rm -rf /tmp/wordpress

    WP_SALTS=$(wget -qO- https://api.wordpress.org/secret-key/1.1/salt/)

    cat > "$WPDIR/wp-config.php" << EOF
<?php
define('DB_NAME', '${MYSQL_DATABASE}');
define('DB_USER', '${MYSQL_USER}');
define('DB_PASSWORD', '${MYSQL_PASSWORD}');
define('DB_HOST', 'mariadb');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

\$table_prefix = 'wp_';

${WP_SALTS}

define('WP_DEBUG', false);

if ( !defined('ABSPATH') )
    define('ABSPATH', __DIR__ . '/');

require_once ABSPATH . 'wp-settings.php';
EOF

    chown -R www-data:www-data "$WPDIR"

    echo "Installing WordPress core..."
    wp core install \
        --url="https://${DOMAIN_NAME}" \
        --title="Inception" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --path="$WPDIR" \
        --allow-root

    echo "Creating secondary user..."
    wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
        --user_pass="${WP_USER_PASSWORD}" \
        --role=author \
        --path="$WPDIR" \
        --allow-root

    echo "WordPress setup complete."
else
    echo "WordPress already initialized, skipping setup."
fi

echo "Starting PHP-FPM..."
exec php-fpm8.2 -F