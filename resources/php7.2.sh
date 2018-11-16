#!/bin/sh

##
# Acuparse Installation Script
# PHP 7.0 to 7.2 Upgrader
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

if [ `id -u` != "0" ]; then
	echo "Sorry, you are not root."
	exit 1
fi

printf "Upgrading PHP to 7.2\n\n"

printf "Installation Ready!\n\nThis process will attempt to remove PHP 5, 7.0, and 7.1 then install PHP 7.2.\nThis is your last chance to exit.\n\n"
	
printf "When ready, Press [ENTER] to continue\n"
read READY

printf "Removing PHP 5\n\n"
sleep 1
apt-get remove php5* -y
a2dismod php5

printf "Removing PHP 7.0\n\n"
sleep 1
apt-get remove php7.0* -y
a2dismod php7.0

printf "Removing PHP 7.1\n\n"
sleep 1
apt-get remove php7.1* -y
a2dismod php7.1

printf "\nInstalling PHP 7.2\n\n"
OS=$(cat /etc/*release | grep '^ID=' | awk -F=  '{ print $2 }')
if [ "$OS" = "debian" ] || [ "$OS" = "raspbian" ]; then
	printf "DEBIAN DETECTED!\nAdding DEB.SURY.ORG repository.\n\n"
	apt-get install ca-certificates apt-transport-https -y
	wget -q https://packages.sury.org/php/apt.gpg -O- | apt-key add -
	echo "deb https://packages.sury.org/php/ stretch main" | tee /etc/apt/sources.list.d/php.list
fi
apt-get update
sleep 1
apt-get install php7.2 libapache2-mod-php7.2 php7.2-mysql php7.2-gd php7.2-curl php7.2-json php7.2-cli php7.2-common -y
a2enmod php7.2

printf "\nCleanup APT\n\n"
sleep 1
apt purge
apt clean
apt autoremove -y

printf "\nRestarting Apache\n\n"
sleep 1
systemctl restart apache2

printf "\nDONE!\n"
