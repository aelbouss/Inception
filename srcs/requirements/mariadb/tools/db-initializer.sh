#!/bin/bash
set -e

# Environment variables 
DB_NAME="${DB_NAME}"
DB_USER_NAME="${DB_USER_NAME}"

# Extract secrets

DB_PASSWORD=$(cat /run/secrets/db_password)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
DB_USER_PASSWORD=$(cat /run/secrets/db_user_password)

DIR="/var/lib/mysql"

# 1. Create runtime and data directories
mkdir -p "$DIR" /run/mysqld

# 2. Set ownership and permissions
chown -R mysql:mysql "$DIR" /run/mysqld
chmod 750 "$DIR"

# 3. First-boot initialization check
if [ ! -d "$DIR/mysql" ]; then
    echo "Initializing MariaDB system tables..."
    mariadb-install-db --user=mysql --datadir="$DIR" > /dev/null

    echo "Starting temporary MariaDB daemon..."
    mariadbd --user=mysql --datadir="$DIR" --skip-networking &

    # Wait for socket to become available
    until mariadmin --socket=/run/mysqld/mysqld.sock ping &>/dev/null; do
        sleep 1
    done

    echo "Configuring database and users..."
    mariadb --socket=/run/mysqld/mysqld.sock <<-EOF
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
        CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
        CREATE USER IF NOT EXISTS '${DB_USER_NAME}'@'%' IDENTIFIED BY '${DB_USER_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER_NAME}'@'%';
        FLUSH PRIVILEGES;
EOF

    echo "Shutting down temporary daemon..."
    mysqladmin --socket=/run/mysqld/mysqld.sock -u root -p"${DB_ROOT_PASSWORD}" shutdown

    echo "Initialization complete."
fi

# 4. Start MariaDB in the foreground as PID 1
echo "Starting MariaDB in foreground..."
exec mariadbd --user=mysql --datadir="$DIR"