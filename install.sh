#!/bin/sh

##
# Acuparse Installer
# @copyright Copyright (C) 2015-2017 Maxwell Power
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

if [ `id -u` != "0" ]; then
    echo "Sorry, you are not root."
    exit 1
fi

cd ~
printf "Acuparse Installation Script\n\n"

printf "This script is designed to be run on a freshly installed Debian/Ubuntu System\n\n"

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

printf "Install Packages\n"
sleep 2
OS=$(cat /etc/*release | grep '^ID=' | awk -F=  '{ print $2 }')

echo "mysql-server mysql-server/root_password password $ROOTPW" | sudo debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $ROOTPW" | sudo debconf-set-selections

if [ "$OS" = "debian" ]; then
        apt-get update && apt-get install git ntp imagemagick apache2 mysql-server php5 libapache2-mod-php5 php5-mysql php5-gd php5-curl php5-cli -y
elif [ "$OS" = "ubuntu" ]; then
        apt-get update && apt-get install git ntp imagemagick apache2 mysql-server php7.0 libapache2-mod-php7.0 php7.0-mysql php7.0-gd php7.0-curl php7.0-json php7.0-cli -y
else
        printf "NO Debian Based OS!"
		exit
fi

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
git remote add -t master -f origin https://github.com/acuparse/acuparse.git
git checkout master
chown -R www-data:www-data /opt/acuparse/src
printf "Done with Git Repo\n\n"

printf "Configuring website\n"
sleep 2
a2dissite 000-default.conf > /dev/null 2>&1
ln config/acuparse.conf /etc/apache2/sites-enabled/
a2enmod rewrite > /dev/null 2>&1
service apache2 restart
printf "Done with Website Config\n\n"

printf "Setting up Acuparse database\n"
sleep 2
mysql -uroot -p$ROOTPW -e "DELETE FROM mysql.user WHERE User='';DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');DROP DATABASE IF EXISTS test;DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';FLUSH PRIVILEGES;" > /dev/null 2>&1
mysql -uroot -p$ROOTPW -e "CREATE DATABASE acuparse; GRANT ALL PRIVILEGES ON acuparse.* TO acuparse@localhost IDENTIFIED BY '$DBPW'; GRANT SUPER, EVENT ON *.* TO acuparse@localhost" > /dev/null 2>&1
printf "Done with Database\n\n"

printf "Installing Cronjob\n"
sleep 2
(crontab -l 2>/dev/null; echo "* * * * * php /opt/acuparse/cron/cron.php > /opt/acuparse/logs/cron.log 2>&1") | crontab -
printf "Done with Cron\n\n"

printf "Setup Complete!\nConnect to your system using a browser to continue configuration.\n"
exit
