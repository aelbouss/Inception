#!/bin/bash
set -e

FTP_USER_PASSWORD=$(cat /run/secrets/ftp_user_password | tr -d '\r\n')

# Ensure secure chroot empty directory exists
mkdir -p /var/run/vsftpd/empty

# Check if the group exists, create if not
if ! getent group "$FTP_GROUP" &> /dev/null; then
    groupadd "$FTP_GROUP"
fi

# Check if the FTP user exists, create if not
if ! id "$FTP_USER" &> /dev/null; then
    useradd -M -g "$FTP_GROUP" -G www-data -d "$FTP_DATA" -s /bin/bash "$FTP_USER"
    echo "$FTP_USER:$FTP_USER_PASSWORD" | chpasswd
fi

# Ensure data directory exists and set permissions
mkdir -p "$FTP_DATA"
chown -R "$FTP_USER":"$FTP_GROUP" "$FTP_DATA"
chmod -R 775 "$FTP_DATA"

# Execute the command passed as arguments to the script
exec "$@"