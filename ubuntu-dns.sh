#!/bin/bash

# Variables
DOMAIN="yourdomain.com"
SERVER_IP="1.1.1.1"
SECONDARY_DNS_IP=""  # Add your secondary DNS IP if you have one
ZONE_FILE="/etc/bind/db.$DOMAIN"
REVERSE_ZONE_FILE="/etc/bind/db.$(echo $SERVER_IP | awk -F. '{print $3"."$2"."$1}').in-addr.arpa"

# Update and install bind9
echo "Updating system and installing BIND9..."
sudo apt update && sudo apt install -y bind9 bind9utils bind9-doc

# Configure BIND9 settings
echo "Configuring BIND9 for $DOMAIN..."

# Edit named.conf.local
echo "Adding zone configuration to named.conf.local..."
sudo bash -c "cat >> /etc/bind/named.conf.local" <<EOL

zone "$DOMAIN" {
    type master;
    file "$ZONE_FILE";
};

zone "$(echo $SERVER_IP | awk -F. '{print $3"."$2"."$1}').in-addr.arpa" {
    type master;
    file "$REVERSE_ZONE_FILE";
};
EOL

# Create forward zone file
echo "Creating forward zone file for $DOMAIN..."
sudo cp /etc/bind/db.local $ZONE_FILE
sudo bash -c "cat > $ZONE_FILE" <<EOL
;
; BIND data file for $DOMAIN
;
\$TTL    604800
@       IN      SOA     ns1.$DOMAIN. admin.$DOMAIN. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      ns1.$DOMAIN.
@       IN      NS      ns2.$DOMAIN.

@       IN      A       $SERVER_IP
ns1     IN      A       $SERVER_IP
ns2     IN      A       $SECONDARY_DNS_IP

www     IN      A       $SERVER_IP
EOL

# Create reverse zone file
echo "Creating reverse zone file..."
sudo cp /etc/bind/db.127 $REVERSE_ZONE_FILE
sudo bash -c "cat > $REVERSE_ZONE_FILE" <<EOL
;
; BIND reverse data file for $SERVER_IP
;
\$TTL    604800
@       IN      SOA     ns1.$DOMAIN. admin.$DOMAIN. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      ns1.$DOMAIN.
$(echo $SERVER_IP | awk -F. '{print $4}')    IN      PTR     $DOMAIN.
EOL

# Restart BIND9 service
echo "Restarting BIND9..."
sudo systemctl restart bind9

# Enable BIND9 to start at boot
sudo systemctl enable bind9

# Allow DNS service through firewall
echo "Allowing DNS service through firewall..."
sudo ufw allow 53/tcp
sudo ufw allow 53/udp

# Test DNS server configuration
echo "Testing DNS server..."
dig @$SERVER_IP $DOMAIN

echo "DNS server installation and configuration for $DOMAIN is complete!"
