#!/bin/bash
set -e

# Environment variables
DB_NAME="${DB_NAME}"
DB_USER="${DB_USER}"
MYSQL_HOST="${MYSQL_HOST}"
WP_USER="${WP_USER}"
WP_ADMIN_USER="${WP_ADMIN_NAME}"
WP_TITLE="${WP_TITLE}"
WP_URL="${WP_URL}"
WP_USER_EMAIL="${WP_USER_EMAIL}"
WP_ADMIN_EMAIL="${WP_ADMIN_EMAIL}"

# Extract secrets
MYSQL_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

# Create PHP runtime
WEB_ROOT="/var/www/html"
mkdir -p /run/php
chown www-data:www-data /run/php

# Initialization guard
if [ ! -f "$WEB_ROOT/wp-config.php" ]; then
    # Automatically generate a config using environment variables
    wp config create \
        --dbname="${DB_NAME}" \
        --dbuser="${DB_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="${MYSQL_HOST}" \
        --path="${WEB_ROOT}"

    # Install the WordPress core
    wp core install \
        --url="${WP_URL}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --path="${WEB_ROOT}"

    # Create a secondary user
    wp user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}" \
        --path="${WEB_ROOT}"

    chown -R www-data:www-data "${WEB_ROOT}"
fi

exec php-FPM -F