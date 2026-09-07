#!/bin/bash
set -e

# Target folder for the certificate
CERT_DIR="/etc/nginx/certs"

# Certificate filenames
CERT_FILE="cert.pem"
# private key file name

P_KEY="nginx.key"

# Create the certificate folder if it doesn't exist
mkdir -p "$CERT_DIR"

# Check if the certificate or key is missing, then generate them
if [ ! -f "$CERT_DIR/$CERT_FILE" ] || [ ! -f "$CERT_DIR/$P_KEY" ]; then
    echo "Generating self-signed TLS certificate for Nginx..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$CERT_DIR/$P_KEY" \
        -out "$CERT_DIR/$CERT_FILE" \
        -subj "/CN=aelbouss.42.fr"
fi

# Execute the CMD passed to the container
exec "$@"



