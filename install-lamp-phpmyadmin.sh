#!/bin/bash

# Update package repository
echo "Updating package repository..."
sudo apt update

# Install Apache
echo "Installing Apache..."
sudo apt install apache2 -y

# Enable Apache to run on system boot
echo "Enabling Apache to start on boot..."
sudo systemctl start apache2
sudo systemctl enable apache2

# Install MySQL
echo "Installing MySQL..."
sudo apt install mysql-server -y

# Secure MySQL installation
echo "Securing MySQL installation..."
sudo mysql_secure_installation

# Install PHP
echo "Installing PHP and necessary modules..."
sudo apt install php libapache2-mod-php php-mysql -y

# Restart Apache to apply changes
echo "Restarting Apache to apply PHP changes..."
sudo systemctl restart apache2

# Check Apache, MySQL, and PHP versions
echo "Checking Apache, MySQL, and PHP versions..."
apache2 -v
mysql --version
php -v

# Create a PHP test file to verify LAMP installation
echo "Creating a PHP test file..."
echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php

# Adjust firewall to allow web traffic (optional)
echo "Adjusting firewall to allow Apache traffic..."
sudo ufw allow in "Apache Full"

# Install phpMyAdmin
echo "Installing phpMyAdmin..."
sudo apt install phpmyadmin php-mbstring php-zip php-gd php-json php-curl -y

# Enable mbstring module in PHP
echo "Enabling mbstring PHP module..."
sudo phpenmod mbstring

# Restart Apache to apply changes
echo "Restarting Apache again..."
sudo systemctl restart apache2

# Set up phpMyAdmin (optional: auto-configure)
# Link phpMyAdmin to Apache configuration
echo "Linking phpMyAdmin to Apache..."
sudo ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin

# Set permissions for phpMyAdmin folder (optional)
sudo chmod 755 /usr/share/phpmyadmin

# Check phpMyAdmin installation
echo "phpMyAdmin installation complete."
echo "You can access phpMyAdmin by visiting http://your_server_ip/phpmyadmin"

# Final message
echo "LAMP stack with phpMyAdmin installation complete!"
