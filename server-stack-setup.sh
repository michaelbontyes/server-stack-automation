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
  apt-get install -y mysql-server
  apt-get install -y phpmyadmin
  apt-get install -y php5-curl ;;
  *) exit
esac

#SFTP USER
echo $RED "

LET'S START BY CREATING THE SFTP USER AND IT'S PASSWORD

" $NC
sudo adduser webdeploy

###### DELETE THIS SECTION BEFORE RUNNING ####
#sudo rm -R /var/www/vhosts/*
#sudo rm -R /etc/apache2/sites-available/*.conf
##############################################

#VHOSTS
echo $RED "
PLEASE ENTER A VALUE FOR THE FOLLOWING VHOSTS: (Ex, mysite-dev.edlfb.net)

" $NC
echo $RED "
DEV: " $NC
read dev

echo $RED "
STAGING: " $NC
read staging

echo $RED " The dev environment is: $dev"
echo $RED " And the staging environment is: $staging"
echo $RED "

Is this correct? (yes/no)

" $NC
read answer

case $answer in
  y|yes|Y|Yes|YES|YEs|YeS|yEs|yES|yeS|Oui|oui) break ;;
  *) echo $RED " Please enter value for the following vhosts"
  echo " dev: " $NC
  read dev
  echo " staging: " $NC
  read staging
  echo $RED " The dev environment is: $dev"
  echo $RED " The staging environment is: $staging"
esac

echo $RED "
CREATING VHOSTS IN /var/www/vhosts
" $NC
mkdir -p /var/www/vhosts/$dev
echo $RED "
CREATED /var/www/vhosts/$dev
" $NC
mkdir -p /var/www/vhosts/$staging
echo $RED "
CREATED /var/www/vhosts/$staging
" $NC

sleep 2

#APACHE
echo $RED "
CREATING APACHE CONFIG FILES

" $NC
touch /etc/apache2/sites-available/$dev.conf
touch /etc/apache2/sites-available/$staging.conf

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

        SSLEngine on
        SSLCertificateFile   /root/edlfb16.crt
        SSLCertificateKeyFile /root/edlfb16.key
        SSLCertificateChainFile /root/edlfb-ca.crt

        <FilesMatch \"\.(cgi|shtml|phtml|php)$\">
        SSLOptions +StdEnvVars
        </FilesMatch>

        BrowserMatch \"MSIE [2-6]\"                 nokeepalive ssl-unclean-shutdown                 downgrade-1.0 force-response-1.0
        BrowserMatch \"MSIE [17-9]\" ssl-unclean-shutdown

</VirtualHost>
" >> /etc/apache2/sites-available/$dev.conf

cat /etc/apache2/sites-available/$dev.conf
echo $RED "
DEV CONFIG FILE CREATED
" $NC

sleep 2

echo " <VirtualHost *:80>
        ServerName $staging

        DocumentRoot /var/www/vhosts/$staging

        RewriteEngine On
        RewriteCond %{HTTPS} off
        RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI}

        <Directory /var/www/vhosts/$staging>

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

        ErrorLog /var/log/apache2/$staging-error.log
        CustomLog /var/log/apache2/$staging-access.log combined
        LogLevel warn
</VirtualHost>

<VirtualHost *:443>
        ServerName $staging

        DocumentRoot /var/www/vhosts/$staging

        <Directory /var/www/vhosts/$staging>

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

        ErrorLog /var/log/apache2/$staging-error.log
        CustomLog /var/log/apache2/$staging-access.log combined
        LogLevel warn

        SSLEngine on
        SSLCertificateFile   /root/edlfb16.crt
        SSLCertificateKeyFile /root/edlfb16.key
        SSLCertificateChainFile /root/edlfb-ca.crt

        <FilesMatch \"\.(cgi|shtml|phtml|php)$\">
        SSLOptions +StdEnvVars
        </FilesMatch>

        BrowserMatch \"MSIE [2-6]\"                 nokeepalive ssl-unclean-shutdown                 downgrade-1.0 force-response-1.0
        BrowserMatch \"MSIE [17-9]\" ssl-unclean-shutdown

</VirtualHost>
" >> /etc/apache2/sites-available/$staging.conf

cat /etc/apache2/sites-available/$staging.conf
echo $RED "
STAGING CONFIG FILE CREATED

" $NC

echo $RED "
ENTER HTPASSWD CREDENTIALS: (THIS WILL BE THE HASHED preview:skbf8*fbsjhv&bhkbgs7.)
" $NC
read creds

echo " $creds" >> /etc/apache2/.htpasswd

sleep 2

echo $RED "
ENABLING THE DEV AND STAGING SITES

" $NC
sudo a2ensite $dev.conf
sudo a2ensite $staging.conf

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
MaxRequestWorkers 90
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
sudo service apache2 restart

#DATABASES
echo $RED "
CREATING DATABASES AND DB USERS

ENTER THE DEV DB USER: " $NC
read devuser

echo $RED "
ENTER THE DEV DB USER'S PASSWORD: " $NC
read devpass

echo $RED "
ENTER THE STAGING DB USER: " $NC
read staginguser

echo $RED "
ENTER THE STAGING DB USER'S PASSWORD: " $NC
read stagingpass

echo $RED "
ENTER THE DB HOST (In most cases it would be 'localhost'): " $NC
read dbhost

mysql -u root -p<< EOF
create database $devuser;
create user '$devuser'@'$dbhost' identified by '$devpass';
grant usage on *.* to $devuser@$dbhost identified by '$devpass';
grant all privileges on $devuser.* to $devuser@$dbhost ;

create database $staginguser;
create user '$staginguser'@'$dbhost' identified by '$stagingpass';
grant usage on *.* to $staginguser@$dbhost identified by '$stagingpass';
grant all privileges on $staginguser.* to $staginguser@$dbhost ;

flush privileges;
EOF


#WORDPRESS
echo $RED "
FETCHING PRE-REQUISITES TO INSTALL WORDPRESS

" $NC
sudo apt-get update
sudo apt-get install -y wget
sudo apt-get install -y zip
sudo apt-get install -y unzip

echo $RED "
INSTALLING LATEST WORDPRESS

" $NC
cd /var/www/
wget https://wordpress.org/latest.zip
unzip latest.zip
sudo rm latest.zip
cp -R wordpress/* /var/www/vhosts/$dev
cp -R wordpress/* /var/www/vhosts/$staging
sudo rm /var/www/vhosts/$dev/readme.html
sudo rm /var/www/vhosts/$staging/readme.html
sudo rm -R /var/www/vhosts/$dev/wp-content/themes/*
sudo rm -R /var/www/vhosts/$staging/wp-content/themes/*
sudo rm -R /var/www/vhosts/$dev/wp-content/plugins/*
sudo rm -R /var/www/vhosts/$staging/wp-content/plugins/*
sudo rm -R /var/www/wordpress/

#WP-CLI
echo $RED "
INSTALLING WP-CLI

" $NC
cd /var/www/vhosts/$dev/
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
sudo chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp

echo $RED "
ASSIGNING PROPER PERMISSIONS TO VHOSTS

" $NC
sudo chown -R www-data:www-data /var/www/vhosts/
sudo chmod -R 755 /var/www/vhosts/
sudo chown -R webdeploy /var/www/vhosts/$dev/wp-content
sudo chown -R webdeploy /var/www/vhosts/$staging/wp-content
sudo chmod -R 775 /var/www/vhosts/$dev/wp-content
sudo chmod -R 775 /var/www/vhosts/$staging/wp-content
sudo chown root:root /var/www/vhosts/$dev/xmlrpc.php
sudo chmod 700 /var/www/vhosts/$dev/xmlrpc.php
sudo chown root:root /var/www/vhosts/$staging/xmlrpc.php
sudo chmod 700 /var/www/vhosts/$staging/xmlrpc.php

ls -la /var/www/vhosts/

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

echo $RED "
AND THAT'S IT!
Now please verify the settings quickly and navigate to $dev and $staging to complete the WP quick install
" $NC
