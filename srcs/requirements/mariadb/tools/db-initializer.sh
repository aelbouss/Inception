#!/bin/bash
set -e

DB_PASSWORD=$(cat /run/secrets/db_password | tr -d '\r\n')
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password | tr -d '\r\n')

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

# If the database is not yet created
if [ ! -d "/var/lib/mysql/${DB_NAME}" ]; then

    mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null

    # Start temporary server in background
    mysqld --user=mysql &
    PID=$!

    # Wait until it is ready
    until mariadb-admin ping -h localhost --silent; do
        sleep 1
    done

    # Configure database, user, and root
    mariadb -h localhost -u root << EOF
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

    # Stop temporary server
    mariadb-admin -h localhost -u root -p"${DB_ROOT_PASSWORD}" shutdown
    wait "$PID"
fi

# Run MariaDB in foreground
exec mysqld --user=mysql --bind-address=0.0.0.0