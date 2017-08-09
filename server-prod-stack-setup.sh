#!sbin/bash
RED='\033[0;31m'
NC='\033[0m' # No Color

echo $RED "
INSTALLATION PRE-REQUISITES

0. BE ROOT
1. Install apache2: NO need to configure
2. Install mysql-server: Set Root password
3. Install phpmyadmin and secure it
4. Create users and databases for both dev and staging
5. Ensure the EDLFB certificates and key are in the /root folder

WOULD YOU LIKE TO INSTALL THE REQUIRED PACKAGES? (yes/no/exit)
" $NC
read prereq
case $prereq in
  n|no|No|nO|NO|non|Non|nOn|noN|NOn|NoN|NON) break ;;
  y|yes|Y|Yes|YES|YEs|YeS|yEs|yES|yeS|Oui|oui) apt-get update
  apt-get install -y apache2
  #apt-get install -y mysql-server
  apt-get install -y php5
  apt-get install -y php-mysql
  apt-get install -y php5-curl ;;
  *) exit
esac

#SFTP USER
echo $RED "

LET'S START BY CREATING THE SFTP USER AND IT'S PASSWORD

" $NC
sudo adduser webdeploy

#VHOSTS
echo "Please enter a value for the new vhost:
"
read dev

echo "Creating vhosts in /var/www/vhosts"
mkdir -p /var/www/vhosts/$dev

sleep 2

#APACHE
echo "Creating apache config files"
touch /etc/apache2/sites-available/$dev.conf

echo " <VirtualHost *:80>
        ServerName $dev

        DocumentRoot /var/www/vhosts/$dev

        RewriteEngine On
        RewriteCond %{HTTPS} off
        RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI}

        <Directory /var/www/vhosts/$dev>

            Header always set X-Xss-Protection \"1; mode=block\"
            Header always set X-Frame-Options SAMEORIGIN

            Options -Indexes +FollowSymLinks -MultiViews
            AllowOverride All
            AuthType Basic
            Order allow,deny
            AuthName \"Preview\"
            AuthUserFile /etc/apache2/.htpasswd
            Require valid-user
            Allow from localhost
            Satisfy Any
        </Directory>

        <files xmlrpc.php>
        Order allow,deny
        Deny from all
        </files>

        ErrorLog /var/log/apache2/$dev-error.log
        CustomLog /var/log/apache2/$dev-access.log combined
        LogLevel warn
</VirtualHost>

<VirtualHost *:443>
        ServerName $dev

        DocumentRoot /var/www/vhosts/$dev

        <Directory /var/www/vhosts/$dev>

            Header always set X-Xss-Protection \"1; mode=block\"
            Header always set X-Frame-Options SAMEORIGIN

            Options -Indexes +FollowSymLinks -MultiViews
            AllowOverride All
            AuthType Basic
            Order allow,deny
            AuthName \"Preview\"
            AuthUserFile /etc/apache2/.htpasswd
            Require valid-user
            Allow from localhost
            Satisfy Any
        </Directory>

        <files xmlrpc.php>
        Order allow,deny
        Deny from all
        </files>

        ErrorLog /var/log/apache2/$dev-error.log
        CustomLog /var/log/apache2/$dev-access.log combined
        LogLevel warn

        <FilesMatch \"\.(cgi|shtml|phtml|php)$\">
        SSLOptions +StdEnvVars
        </FilesMatch>

        BrowserMatch \"MSIE [2-6]\"                 nokeepalive ssl-unclean-shutdown                 downgrade-1.0 force-response-1.0
        BrowserMatch \"MSIE [17-9]\" ssl-unclean-shutdown

</VirtualHost>
" >> /etc/apache2/sites-available/$dev.conf

cat /etc/apache2/sites-available/$dev.conf
echo "dev config file created"

sleep 2

echo $RED "
ENTER HTPASSWD CREDENTIALS: (THIS WILL BE THE HASHED preview:skbf8*fbsjhv&bhkbgs7.)
" $NC
read creds

echo " $creds" >> /etc/apache2/.htpasswd

sleep 2

echo "Enabling the new site"
sudo a2ensite $dev.conf

echo $RED "
DISABLING DEFAULT SITES

" $NC
sudo a2dissite 000-default.conf
sudo a2dissite default-ssl.conf

echo $RED "
SETTING SERVER NAME

" $NC
echo "ServerName $dev

# HTTP SLOW CONTROL
MaxRequestWorkers 100
LimitRequestLine 4094
LimitRequestBody 20971520
LimitRequestFieldSize 4094
LimitRequestFields 50

" >> /etc/apache2/apache2.conf

echo $RED "
ENABLING APACHE2 MODULES

" $NC
sudo a2enmod ssl
sudo a2enmod rewrite
sudo a2enmod headers
sudo a2enmod expires
sudo php5enmod mcrypt

sudo apt-get -y install apache2-dev libtool git
git clone https://github.com/cloudflare/mod_cloudflare.git && cd mod_cloudflare
apxs -a -i -c mod_cloudflare.c

sudo service apache2 restart

# WordPress
echo $RED "
FETCHING PRE-REQUISITES TO INSTALL WORDPRESS

" $NC
sudo apt-get update
sudo apt-get install -y wget
sudo apt-get install -y zip
sudo apt-get install -y unzip

echo "Installing Latest WordPress"
cd /var/www/
wget https://wordpress.org/latest.zip
unzip latest.zip
sudo rm latest.zip
cp -R wordpress/* /var/www/vhosts/$dev
sudo rm -R /var/www/vhosts/$dev/wp-content/themes/*
sudo rm -R /var/www/vhosts/$dev/wp-content/plugins/*
sudo rm -R /var/www/wordpress/

#DATABASES
# echo "Creating databases and users
# Enter the user for the DB:
# "
# read devuser
#
# echo "Enter the password for the DB:
# "
# read devpass
#
# echo "Enter the DB Host (In most cases it would be 'localhost'):
# "
# read dbhost
#
# echo "You will now be prompted for the root user's MySQL password:
# "
#
# mysql -u root -p<< EOF
# create database $devuser;
# create user '$devuser'@'$dbhost' identified by '$devpass';
# grant usage on *.* to $devuser@$dbhost identified by '$devpass';
# grant all privileges on $devuser.* to $devuser@$dbhost ;
#
# flush privileges;
# EOF

#WP-CLI
cd /var/www/vhosts/$dev/
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
sudo chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp

echo "Assigning proper permissions to vhosts"
sudo chown -R www-data:www-data /var/www/vhosts/$dev
sudo chmod -R 775 /var/www/vhosts/$dev
sudo chown -R webdeploy /var/www/vhosts/$dev/wp-content
sudo chmod -R 775 /var/www/vhosts/$dev/wp-content
sudo chown root:root /var/www/vhosts/$dev/xmlrpc.php
sudo chmod 700 /var/www/vhosts/$dev/xmlrpc.php

#UFW
echo $RED "
SETTIGN UP BASIC UFW RULES

" $NC
sudo ufw enable
ufw default deny incoming
ufw default allow outgoing
sudo ufw allow 80
sudo ufw allow 443

echo $RED "
DOES THE SERVER NEED TO SEND MAIL? (yes/no)

" $NC

read mail
case $mail in
  n|no|No|nO|NO|non|Non|nOn|noN|NOn|NoN|NON) sudo ufw deny out 25 ;;
  y|yes|Y|Yes|YES|YEs|YeS|yEs|yES|yeS|Oui|oui) break ;;
  *) break ;;
esac


echo "
AND THAT'S IT!
Now please verify the settings quickly and navigate to $dev to complete the WP quick install"
