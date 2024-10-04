#!/bin/bash

# chmod +x create-ssl-apache.sh

# Check if OpenSSL is installed, if not, install it
if ! command -v openssl &> /dev/null
then
    echo "OpenSSL not found, installing..."
    sudo apt update
    sudo apt install openssl -y
else
    echo "OpenSSL is already installed."
fi

# Check if Apache is installed, if not, install it
if ! command -v apache2 &> /dev/null
then
    echo "Apache not found, installing..."
    sudo apt install apache2 -y
else
    echo "Apache is already installed."
fi

# Enable necessary Apache modules
echo "Enabling SSL and Rewrite modules in Apache..."
sudo a2enmod ssl
sudo a2enmod rewrite

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
echo "Generating private key for $DOMAIN..."
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

# Create Apache SSL Virtual Host configuration
echo "Creating Apache SSL Virtual Host for $DOMAIN..."
SSL_CONF="/etc/apache2/sites-available/$DOMAIN-ssl.conf"
sudo bash -c "cat > $SSL_CONF" <<EOL
<VirtualHost *:443>
    ServerAdmin $EMAIL
    ServerName $DOMAIN
    ServerAlias www.$DOMAIN

    DocumentRoot /var/www/html/$DOMAIN

    SSLEngine on
    SSLCertificateFile $CERT_DIR/$DOMAIN.crt
    SSLCertificateKeyFile $CERT_DIR/$DOMAIN.key

    <Directory /var/www/html/$DOMAIN>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/$DOMAIN-error.log
    CustomLog \${APACHE_LOG_DIR}/$DOMAIN-access.log combined
</VirtualHost>
EOL

# Enable the new SSL site configuration
echo "Enabling new Apache SSL site for $DOMAIN..."
sudo a2ensite $DOMAIN-ssl.conf

# Optional: Create a redirect from HTTP to HTTPS
echo "Setting up HTTP to HTTPS redirection..."
HTTP_CONF="/etc/apache2/sites-available/$DOMAIN.conf"
sudo bash -c "cat > $HTTP_CONF" <<EOL
<VirtualHost *:80>
    ServerAdmin $EMAIL
    ServerName $DOMAIN
    ServerAlias www.$DOMAIN

    DocumentRoot /var/www/html/$DOMAIN

    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]

    <Directory /var/www/html/$DOMAIN>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/$DOMAIN-error.log
    CustomLog \${APACHE_LOG_DIR}/$DOMAIN-access.log combined
</VirtualHost>
EOL

# Enable the HTTP to HTTPS redirection
sudo a2ensite $DOMAIN.conf

# Reload Apache to apply the changes
echo "Restarting Apache to apply changes..."
sudo systemctl restart apache2

# Final instructions
echo "SSL setup completed for $DOMAIN!"
echo "The certificate is stored at: $CERT_DIR/$DOMAIN.crt"
echo "The private key is stored at: $CERT_DIR/$DOMAIN.key"
echo "You can now access your site at: https://$DOMAIN"
