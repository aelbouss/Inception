#!/bin/bash

# the target folder for the certificate
CERT_DIR="/etc/nginx/certs"

# certificate file
CERT_FILE="cert.pem"

#private key file
P_KEY="nginx.key"


# create the  certificate  folder
mkdir -p "$CERT_DIR"

# check if  the  certif  exits if not  ceate it
if [ ! -f "$CERT_DIR/$CERT_FILE" ]; then
    echo "generate self-signed TLS certificate for nginx ..."
    openssl  req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$CERT_DIR/$P_KEY" -out "$CERT_DIR/$CERT_FILE" \
    -subj "/CN=aelbouss.42.fr"
fi

exec "$@"








