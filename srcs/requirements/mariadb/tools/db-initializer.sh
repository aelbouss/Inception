#!/bin/bash
set -e

DIR="/var/lib/mysql"
MARIADB_DATABASE_NAME="mydb"
MARIADB_DATABASE_USER_NAME="Flex"
MARIADB_USER_PASSWORD="pswd"
MARIADB_DATABASE_ROOT_PASSWORD="Flex123"

# 1. Create runtime and data directories
mkdir -p "$DIR" /run/mysqld

# 2. Set ownership and permissions
chown -R mysql:mysql "$DIR" /run/mysqld
chmod 750 "$DIR"

# 3. First-boot initialization check
if [ ! -d "$DIR/mysql" ]; then
    echo "Initializing MariaDB system tables..."
    mariadb-install-db  --user=mysql  --datadir="$DIR"  > /dev/null

    echo "Starting temporary MariaDB daemon..."

    mariadbd --user=mysql --datadir="$DIR" --skip-networking &

    echo "Configuring database and users..."
    mariadb --socket=/run/mysqld/mysqld.sock <<-EOF
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIADB_DATABASE_ROOT_PASSWORD}';
        CREATE DATABASE IF NOT EXISTS \`${MARIADB_DATABASE_NAME}\`;
        CREATE USER IF NOT EXISTS '${MARIADB_DATABASE_USER_NAME}'@'%' IDENTIFIED BY '${MARIADB_USER_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${MARIADB_DATABASE_NAME}\`.* TO '${MARIADB_DATABASE_USER_NAME}'@'%';
        FLUSH PRIVILEGES;
EOF

    echo "Shutting down temporary daemon..."

    mysqladmin -u root -p "${MARIADB_DATABASE_ROOT_PASSWORD}" shutdown ;
    
    echo "Initialization complete."
fi

# 4. Start MariaDB in the foreground as PID 1
echo "Starting MariaDB in foreground..."
exec mariadbd --user=mysql --datadir="$DIR"
