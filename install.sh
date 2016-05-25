#!/bin/bash

# locales
locale-gen en_US.UTF-8 UTF-8
dpkg-reconfigure locales
#dpkg-reconfigure tzdata

# Updating packages
apt-get update
apt-get upgrade

apt-get -y install python-simplejson xauth htop nano curl ntp ntpdate python-software-properties git


mkdir /home/data
mkdir /home/data/cache/
mkdir /home/data/ftp
mkdir /home/data/ftp/template/
mkdir /home/data/ftp/template/qgis
mkdir /home/data/postgresql



apt-get -y install apache2 apache2-mpm-worker libapache2-mod-fcgid php5-cgi php5-curl php5-cli php5-sqlite php5-gd
a2dismod php5
a2enmod actions
a2enmod fcgid
a2enmod ssl
a2enmod rewrite
a2enmod headers
a2enmod deflate

touch /etc/apache2/conf-available/mod_deflate.conf
cat > /etc/apache2/conf-available/mod_deflate.conf <<EOF
    <Location />
	    # Insert filter
	    SetOutputFilter DEFLATE
	    # Netscape 4.x encounters some problems ...
	    BrowserMatch ^Mozilla/4 gzip-only-text/html
	    # Netscape 4.06-4.08 encounter even more problems
	    BrowserMatch ^Mozilla/4\.0[678] no-gzip
	    # MSIE pretends it is Netscape, but all is well
	    BrowserMatch \bMSIE !no-gzip !gzip-only-text/html
	    # Do not compress images
	    SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png)$ no-gzip dont-vary
	    # Ensure that proxy servers deliver the right content
	    Header append Vary User-Agent env=!dont-vary
    </Location>
EOF


 cat > /etc/apache2/conf-available/php.conf << EOF
<Directory /usr/share>
  AddHandler fcgid-script .php
  FCGIWrapper /usr/lib/cgi-bin/php5 .php
  Options ExecCGI FollowSymlinks Indexes
</Directory>
<Files ~ (\.php)>
  AddHandler fcgid-script .php
  FCGIWrapper /usr/lib/cgi-bin/php5 .php
  Options +ExecCGI
  allow from all
</Files>
EOF

a2enconf php

# configuring worker
# aller au worker et mettre par exemple
cat > /etc/apache2/apache2.conf <<EOF
<IfModule mpm_worker_module>
  StartServers       4
  MinSpareThreads    25
  MaxSpareThreads    100
  ThreadLimit          64
  ThreadsPerChild      25
  MaxClients        150
  MaxRequestsPerChild   0
</IfModule>
EOF

# Open the mod_fcgid configuration file
# Paste the following content and adapt it
cat > /etc/apache2/mods-enabled/fcgid.conf <<EOF
<IfModule mod_fcgid.c>
  AddHandler    fcgid-script .fcgi
  FcgidConnectTimeout 300
  FcgidIOTimeout 300
  FcgidMaxProcessesPerClass 50
  FcgidMinProcessesPerClass 20
  FcgidMaxRequestsPerProcess 500
  IdleTimeout   300
  BusyTimeout   300
</IfModule>
EOF

service apache2 restart

¶
# Creating a user accountr
MYUSER=gis
useradd -g client -d /home/data/ftp/$MYUSER -s /bin/ftponly -m $MYUSER -k /home/data/ftp/template/
passwd $MYUSER
# Fix the user's FTP root
chmod a-w /home/data/ftp/$MYUSER
# Creating empty directories that will be the future Lizmap Web Client directories
mkdir /home/data/ftp/$MYUSER/qgis/rep1 && chown $MYUSER:client /home/data/ftp/$MYUSER/qgis/rep1
mkdir /home/data/ftp/$MYUSER/qgis/rep2 && chown $MYUSER:client /home/data/ftp/$MYUSER/qgis/rep2
mkdir /home/data/ftp/$MYUSER/qgis/rep3 && chown $MYUSER:client /home/data/ftp/$MYUSER/qgis/rep3
mkdir /home/data/ftp/$MYUSER/qgis/rep4 && chown $MYUSER:client /home/data/ftp/$MYUSER/qgis/rep4
mkdir /home/data/ftp/$MYUSER/qgis/rep5 && chown $MYUSER:client /home/data/ftp/$MYUSER/qgis/rep5
# Create a directory to store the cached server
mkdir /home/data/cache/$MYUSER
chmod 700 /home/data/cache/$MYUSER -R
chown www-data:www-data /home/data/cache/$MYUSER -R


# Add the repository UbuntuGis
cat >> /etc/apt/sources.list.d/debian-gis.list <<EOF
deb http://qgis.org/debian trusty main
deb-src http://qgis.org/debian trusty main
EOF

# Add keys
sudo gpg --recv-key DD45F6C3
sudo gpg --export --armor DD45F6C3 | sudo apt-key add -

# Update package list
sudo apt-get update

# Install QGIS Server
sudo apt-get -y --force-yes install qgis-server python-qgis


#intstall liz client
sudo su # only useful if you are not logged in as root
apt-get update # update packages
apt-get -y install apache2 php5 curl php5-curl php5-sqlite php5-pgsql php5-gd apache2-mpm-worker # installation of apache2, php, curl, gd, sqlite and pgsql
a2enmod mpm_worker
service apache2 restart # restart Apache server


cd /var/www/
MYAPP=lizmap-web-client
VERSION=master
# Clone the master branch
git clone https://github.com/3liz/lizmap-web-client.git $MYAPP-$VERSION
# Go into the git repository
cd $MYAPP-$VERSION
# Create a personal branch for your changes
git checkout -b mybranch


cd /var/www/$MYAPP-$VERSION
chown :www-data temp/ lizmap/var/ lizmap/www lizmap/install/qgis/edition/ -R
chmod 775 temp/ lizmap/var/ lizmap/www lizmap/install/qgis/edition/ -R

