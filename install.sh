#!/bin/sh

##
# Acuparse Installer
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
printf "This script is designed to be run on a freshly installed Debian Stretch, Ubuntu 16.04 LTS, or Raspbian System\n\n"

OS=$(cat /etc/*release | grep '^ID=' | awk -F=  '{ print $2 }')
if [ "$OS" = "debian" ] || [ "$OS" = "ubuntu" ] || [ "$OS" = "raspbian" ]; then

	if [ `id -u` != "0" ]; then
		echo "Sorry, you are not root."
		exit 1
	fi

	cd ~
	printf "Acuparse Installation Script\n\n"

	printf "First we need some database credentials ...\n"

	printf "Type your MySQL ROOT password, followed by [ENTER]:\n"
	stty -echo
	read ROOTPW
	stty echo

	printf "Choose a password for the Acuparse database, followed by [ENTER]:\n"
	stty -echo
	read DBPW
	stty echo

	printf "Configure Mail?, y/N, followed by [ENTER]:\n"
	read MAIL

	printf "Configure SSL with Let's Encrypt?, y/N, followed by [ENTER]:\n"
	read LESSL

	if [ "$LESSL" = "y" ] || [ "$LESSL" = "Y" ]; then
		printf "Enter your domain for SSL cert, followed by [ENTER]:\n"
		read LE_DOMAIN

		printf "Enter your email for SSL cert, followed by [ENTER]:\n"
		read LE_EMAIL

		printf "Redirect HTTP to HTTPS?, y/N, followed by [ENTER]:\n"
		read REDIRECT

		if [ "$REDIRECT" = "y" ] || [ "$REDIRECT" = "Y" ]; then
			LE_REDIRECT="redirect"
		else
			LE_REDIRECT="no-redirect"
		fi
        printf "Also secure www.$LE_DOMAIN?, y/N, followed by [ENTER]:\n"
        read SECURE_WWW
    
        if [ "$SECURE_WWW" = "y" ] || [ "$SECURE_WWW" = "Y" ]; then
            LE_SECURE_DOMAINS="-d $LE_DOMAIN -d www.$LE_DOMAIN"
        else
            LE_SECURE_DOMAINS="-d $LE_DOMAIN"
        fi
	fi

	printf "Install Packages\n"
	sleep 2
	echo "mysql-server mysql-server/root_password password $ROOTPW" | sudo debconf-set-selections
	echo "mysql-server mysql-server/root_password_again password $ROOTPW" | sudo debconf-set-selections

	apt-get update && apt-get install git ntp imagemagick exim4 apache2 mysql-server php7.0 libapache2-mod-php7.0 php7.0-mysql php7.0-gd php7.0-curl php7.0-json php7.0-cli -y

	if [ "$MAIL" = "y" ] || [ "$MAIL" = "Y" ]; then
		printf "Configure Mail\n"
		sleep 2
		apt-get install exim4 -y
		dpkg-reconfigure exim4-config
	fi

	printf "Done Installing Packages\n\n"

	printf "Getting source from Git repo\n"
	sleep 2
	git init /opt/acuparse
	cd /opt/acuparse
	if [ -z ${1+x} ]; then GITREPO="master"; else GITREPO=$1; fi
	git remote add -t ${GITREPO} -f origin https://github.com/acuparse/acuparse.git
	git checkout ${GITREPO}
	chown -R www-data:www-data /opt/acuparse/src
	printf "Done with Git Repo\n\n"

	printf "Configuring website\n"
	sleep 2
	a2dissite 000-default.conf > /dev/null 2>&1
	rm /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/default-ssl.conf
	cp /opt/acuparse/config/acuparse.conf /etc/apache2/sites-available/
	cp /opt/acuparse/config/acuparse-ssl.conf /etc/apache2/sites-available/
	a2enmod rewrite > /dev/null 2>&1
	a2enmod ssl > /dev/null 2>&1
	a2ensite acuparse.conf > /dev/null 2>&1
	a2ensite acuparse-ssl.conf > /dev/null 2>&1
	systemctl restart apache2.service
	if [ "$LESSL" = "y" ] || [ "$LESSL" = "Y" ]; then
		printf "Deploying Let's Encrypt Certificate\n"
		sleep 2
		systemctl stop apache2.service
		if [ "$OS" = "ubuntu" ]; then
			apt-get install software-properties-common -y
			add-apt-repository ppa:certbot/certbot -y
			apt-get update > /dev/null 2>&1
		fi
		apt-get install python-certbot-apache -y
		sed -i "s/#ServerName/ServerName $LE_DOMAIN\n    ServerAlias www.$LE_DOMAIN/g" /etc/apache2/sites-available/acuparse-ssl.conf
		if [ "$GITREPO" != "master" ]; then
			certbot -n --authenticator standalone --installer apache --agree-tos --${LE_REDIRECT} --email ${LE_EMAIL} ${LE_SECURE_DOMAINS} --staging
		else
			certbot -n --authenticator standalone --installer apache --agree-tos --${LE_REDIRECT} --email ${LE_EMAIL} ${LE_SECURE_DOMAINS}
		fi
		systemctl stop apache2.service
	fi
	printf "Done with Website Config\n\n"

	printf "Setting up Acuparse database\n"
	sleep 2
	mysql -uroot -p${ROOTPW} -e "DELETE FROM mysql.user WHERE User='';DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');DROP DATABASE IF EXISTS test;DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';FLUSH PRIVILEGES;" > /dev/null 2>&1
	mysql -uroot -p${ROOTPW} -e "CREATE DATABASE acuparse; GRANT ALL PRIVILEGES ON acuparse.* TO acuparse@localhost IDENTIFIED BY '$DBPW'; GRANT SUPER, EVENT ON *.* TO acuparse@localhost" > /dev/null 2>&1
	printf "Done with Database\n\n"

	printf "Installing Cronjob\n"
	sleep 2
	(crontab -l 2>/dev/null; echo "* * * * * php /opt/acuparse/cron/cron.php > /opt/acuparse/logs/cron.log 2>&1") | crontab -
	printf "Done with Cron\n\n"

	printf "Setup Complete!\nConnect to your system using a browser to continue configuration.\n"

else
	printf "NO Debian Based OS!"
fi
exit
