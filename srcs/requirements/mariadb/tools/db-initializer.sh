#!/bin/bash
set -e

DB_NAME="${DB_NAME}"
DB_USER_NAME="${DB_USER}"

DB_PASSWORD=$(cat /run/secrets/db_password | tr -d '\r\n')
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password | tr -d '\r\n')

DIR="/var/lib/mysql"

mkdir -p "$DIR" /run/mysqld
chown -R mysql:mysql "$DIR" /run/mysqld
chmod 750 "$DIR"

if [ ! -d "$DIR/$DB_NAME" ]; then
    echo "Initializing MariaDB system tables..."
    mariadb-install-db --user=mysql --datadir="$DIR" > /dev/null

    echo "Starting temporary MariaDB daemon..."
    mariadbd --user=mysql --datadir="$DIR" --skip-networking &
    DB_PID=$!

    until mariadb-admin --host=localhost --socket=/run/mysqld/mysqld.sock ping &>/dev/null; do
        sleep 1
    done

    echo "Configuring database and users..."
    mariadb --host=localhost --socket=/run/mysqld/mysqld.sock <<EOF
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
CREATE USER IF NOT EXISTS '${DB_USER_NAME}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER_NAME}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

    echo "The users are created and the database initialized..."

    echo "Shutting down temporary daemon..."
    mariadb-admin --host=localhost -u root -p"${DB_ROOT_PASSWORD}" --socket=/run/mysqld/mysqld.sock shutdown
    wait "$DB_PID"

    echo "Initialization complete."
fi

echo "Starting MariaDB in foreground..."
exec mariadbd --user=mysql --datadir="$DIR" --bind-address=0.0.0.0