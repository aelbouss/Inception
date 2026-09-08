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
mkdir -p /run/php /tmp/.wp-cli-cache
chown -R www-data:www-data /run/php /tmp/.wp-cli-cache "${WEB_ROOT}"

wp-cli() {
    WP_CLI_CACHE_DIR=/tmp/.wp-cli-cache su -s /bin/sh www-data -c "/usr/local/bin/wp --path='${WEB_ROOT}' $*"
}

# Wait until the database accepts the credentials WordPress will use.
echo "Waiting for MariaDB..."
until mariadb \
    --protocol=TCP \
    --host="${MYSQL_HOST}" \
    --user="${DB_USER}" \
    --password="${MYSQL_PASSWORD}" \
    --database="${DB_NAME}" \
    --execute="SELECT 1" \
    >/dev/null 2>&1; do
    sleep 2
done
echo "MariaDB is up!"


# Initialization guard
if [ ! -f "$WEB_ROOT/wp-config.php" ]; then
    chown -R www-data:www-data "${WEB_ROOT}"

    if [ ! -f "$WEB_ROOT/index.php" ]; then
        wp-cli core download
    fi

    wp-cli config create \
        --dbname="${DB_NAME}" \
        --dbuser="${DB_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="${MYSQL_HOST}"

    wp-cli core install \
        --url="${WP_URL}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}"

    wp-cli user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}"

    chown -R www-data:www-data "${WEB_ROOT}"
fi

exec php-fpm -F