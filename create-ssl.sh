#!/bin/bash

# chmod +x create-ssl.sh - make script executable

# Check if OpenSSL is installed, if not, install it 
if ! command -v openssl &> /dev/null
then
    echo "OpenSSL not found, installing..."
    sudo apt update
    sudo apt install openssl -y
else
    echo "OpenSSL is already installed."
fi

# Set your domain name and certificate details
DOMAIN="yourdomain.com"
COUNTRY="US"
STATE="YourState"
CITY="YourCity"
ORGANIZATION="YourOrganization"
ORGANIZATIONAL_UNIT="YourUnit"
EMAIL="admin@yourdomain.com"

# Create directory to store the certificate and key
CERT_DIR="/etc/ssl/$DOMAIN"
sudo mkdir -p $CERT_DIR

# Generate private key
echo "Generating private key..."
sudo openssl genrsa -out $CERT_DIR/$DOMAIN.key 2048

# Generate a Certificate Signing Request (CSR)
echo "Generating Certificate Signing Request (CSR)..."
sudo openssl req -new -key $CERT_DIR/$DOMAIN.key -out $CERT_DIR/$DOMAIN.csr \
    -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORGANIZATION/OU=$ORGANIZATIONAL_UNIT/CN=$DOMAIN/emailAddress=$EMAIL"

# Generate self-signed certificate
echo "Generating self-signed certificate..."
sudo openssl x509 -req -days 365 -in $CERT_DIR/$DOMAIN.csr -signkey $CERT_DIR/$DOMAIN.key -out $CERT_DIR/$DOMAIN.crt

# Set permissions on the certificate and key
sudo chmod 600 $CERT_DIR/$DOMAIN.key
sudo chmod 644 $CERT_DIR/$DOMAIN.crt

# Display certificate details
echo "SSL Certificate and Key generated successfully for $DOMAIN"
echo "Certificate Path: $CERT_DIR/$DOMAIN.crt"
echo "Key Path: $CERT_DIR/$DOMAIN.key"

# Example Nginx configuration (Optional)
echo "You can now configure your web server to use this certificate."
echo "For example, in Nginx, you would add the following lines in your server block:"
echo "  ssl_certificate $CERT_DIR/$DOMAIN.crt;"
echo "  ssl_certificate_key $CERT_DIR/$DOMAIN.key;"
