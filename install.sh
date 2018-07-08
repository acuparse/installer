#!/bin/sh

##
# Acuparse Installation Script
# @copyright Copyright (C) 2015-2018 Maxwell Power
# @author Maxwell Power <max@acuparse.com>
# @license MIT
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
##
printf "Acuparse Installation Script v1.2.0\n\n"

OS=$(cat /etc/*release | grep '^ID=' | awk -F=  '{ print $2 }')
if [ "$OS" = "debian" ] || [ "$OS" = "ubuntu" ] || [ "$OS" = "raspbian" ]; then
	cd ~
	if [ `id -u` != "0" ]; then
		printf "ERROR: Installer must be run as root!\n"
		exit 1
	fi

	printf "Pre Install\n\n"
	printf "Make a note of your Acuparse database password.\nYou will need it to complete your install!\n\n"
	
	printf "When ready, Press [ENTER] to continue\n"
	read READY
	
	printf "Enter MySQL ROOT password, followed by [ENTER]:\n"
	stty -echo
	read MYSQL_ROOT_PASSWORD
	stty echo

	printf "Enter ACUPARSE database password, followed by [ENTER]:\n"
	stty -echo
	read ACUPARSE_DATABASE_PASSWORD
	stty echo

	printf "Install Exim mail server?, y/N, followed by [ENTER]:\n"
	read EXIM_ENABLED
	
	printf "Install phpMyAdmin?, y/N, followed by [ENTER]:\n"
	read PHPMYADMIN_ENABLED

	printf "Configure SSL using Let's Encrypt?, y/N, followed by [ENTER]:\n"
	read LE_SSL_ENABLED

	if [ "$LE_SSL_ENABLED" = "y" ] || [ "$LE_SSL_ENABLED" = "Y" ]; then
		printf "\nConfiguring Let's Encrypt\n\n"
		
		printf "Enter FQDN(example.com/hostname.example.com), followed by [ENTER]:\n"
		read LE_FQDN
		
		printf "Also secure www.$LE_FQDN?, y/N, followed by [ENTER]:\n"
        read LE_SECURE_WWW
    
        if [ "$LE_SECURE_WWW" = "y" ] || [ "$LE_SECURE_WWW" = "Y" ]; then
            LE_SECURE_DOMAINS="-d $LE_FQDN -d www.$LE_FQDN"
        else
            LE_SECURE_DOMAINS="-d $LE_FQDN"
        fi

		printf "Certificate Email Address, followed by [ENTER]:\n"
		read LE_EMAIL

		printf "Redirect HTTP to HTTPS?, y/N, followed by [ENTER]:\n"
		read LE_REDIRECT_ENABLED

		if [ "$LE_REDIRECT_ENABLED" = "y" ] || [ "$LE_REDIRECT_ENABLED" = "Y" ]; then
			LE_REDIRECT="redirect"
		else
			LE_REDIRECT="no-redirect"
		fi
	fi
	
	printf "\nInstallation Ready!\n\nThis process will install and configure packages.\nThis is your last chance to exit.\n\n"
	
	printf "When ready, Press [ENTER] to continue\n"
	read READY

	printf "Installing Packages\n\n"
	sleep 1
	echo "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
	echo "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
	
	if [ "$OS" = "debian" ] || [ "$OS" = "raspbian" ]; then
		printf "DEBIAN DETECTED! Adding DEB.SURY.ORG repository.\n"
		apt-get install ca-certificates apt-transport-https -y
		wget -q https://packages.sury.org/php/apt.gpg -O- | apt-key add -
		echo "deb https://packages.sury.org/php/ stretch main" | tee /etc/apt/sources.list.d/php.list
	fi

	apt-get update
	apt-get upgrade -y
	apt-get install git ntp imagemagick exim4 apache2 mysql-server php7.2 libapache2-mod-php7.2 php7.2-mysql php7.2-gd php7.2-curl php7.2-json php7.2-cli php7.2-common -y

	if [ "$PHPMYADMIN_ENABLED" = "y" ] || [ "$PHPMYADMIN_ENABLED" = "Y" ]; then
		printf "Installing phpMyAdmin\n"
		echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
		echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
		echo "phpmyadmin phpmyadmin/mysql/app-pass password " | debconf-set-selections
		apt-get install phpmyadmin -y
	fi
	
	if [ "$EXIM_ENABLED" = "y" ] || [ "$EXIM_ENABLED" = "Y" ]; then
		printf "Installing Exim mail server\n"
		sleep 1
		apt-get install exim4 -y
		printf "Launch exim configuration\n"
		dpkg-reconfigure exim4-config
	fi
	printf "END: Packages\n\n"

	printf "Install Acuparse from git\n"
	sleep 1
	git init /opt/acuparse
	cd /opt/acuparse
	if [ -z ${1+x} ]; then GITREPO="master"; else GITREPO=$1; fi
	git remote add -t ${GITREPO} -f origin https://github.com/acuparse/acuparse.git
	git checkout ${GITREPO}
	chown -R www-data:www-data /opt/acuparse/src
	printf "END: Acuparse\n\n"

	printf "Configuring Apache\n"
	sleep 1
	a2dissite 000-default.conf > /dev/null 2>&1
	rm /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/default-ssl.conf
	cp /opt/acuparse/config/acuparse.conf /etc/apache2/sites-available/
	cp /opt/acuparse/config/acuparse-ssl.conf /etc/apache2/sites-available/
	a2enmod rewrite > /dev/null 2>&1
	a2enmod ssl > /dev/null 2>&1
	a2ensite acuparse.conf > /dev/null 2>&1
	a2ensite acuparse-ssl.conf > /dev/null 2>&1
	if [ "$LE_SSL_ENABLED" = "y" ] || [ "$LE_SSL_ENABLED" = "Y" ]; then
		printf "Deploying Let's Encrypt Certificate\n"
		sleep 1
		systemctl stop apache2.service
		if [ "$OS" = "ubuntu" ]; then
			printf "UBUNTU DETECTED! Using certbot PPA\n"
			apt-get install software-properties-common -y
			add-apt-repository ppa:certbot/certbot -y
			apt-get update > /dev/null 2>&1
		fi
		apt-get install python-certbot-apache -y
		sed -i "s/#ServerName/ServerName $LE_FQDN\n    ServerAlias www.$LE_FQDN/g" /etc/apache2/sites-available/acuparse-ssl.conf
		if [ "$GITREPO" != "master" ]; then
			printf "Requesting cert from STAGING server\n"
			certbot -n --authenticator standalone --installer apache --agree-tos --${LE_REDIRECT} --email ${LE_EMAIL} ${LE_SECURE_DOMAINS} --staging
		else
			printf "Requesting cert from PRODUCTION server\n"
			certbot -n --authenticator standalone --installer apache --agree-tos --${LE_REDIRECT} --email ${LE_EMAIL} ${LE_SECURE_DOMAINS}
		fi
	fi
	systemctl restart apache2.service
	printf "END: Apache Config\n\n"

	printf "Creating Acuparse database\n"
	sleep 1
	mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "DELETE FROM mysql.user WHERE User='';DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');DROP DATABASE IF EXISTS test;DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';FLUSH PRIVILEGES;" > /dev/null 2>&1
	mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "CREATE DATABASE acuparse; GRANT ALL PRIVILEGES ON acuparse.* TO acuparse@localhost IDENTIFIED BY '$ACUPARSE_DATABASE_PASSWORD'; GRANT SUPER, EVENT ON *.* TO acuparse@localhost" > /dev/null 2>&1

	printf "Installing Cron\n"
	sleep 1
	(crontab -l 2>/dev/null; echo "* * * * * php /opt/acuparse/cron/cron.php > /opt/acuparse/logs/cron.log 2>&1") | crontab -

	printf "Running Cleanup\n"
	apt-get autoremove -y
	apt-get clean -y
	apt-get purge -y
	systemctl restart apache2.service
	
	printf "\nAcuparse Installation Complete!\n\n"
	
	printf "Your system IP addresse(s):\n"
	hostname -I
	printf "\nYour system hostname(s):\n"
	hostname -A
	printf "\nConnect to your IP/Hostname with a browser to continue configuration.\n"
else
	printf "ERROR: This script is designed to be run on a freshly installed Debian Stretch(9), Ubuntu 18.04 LTS, or Raspbian Stretch(9) based system\n"
fi
exit