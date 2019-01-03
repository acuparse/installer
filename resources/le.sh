#!/bin/sh

##
# Acuparse Installation Script
# Let's Encrypt Installer
# @copyright Copyright (C) 2015-2019 Maxwell Power
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
printf "Acuparse Certificate Installation Script\n\n"

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

printf "Deploying Let's Encrypt Certificate\n"
sleep 2
if [ "$OS" = "ubuntu" ]; then
	apt-get install software-properties-common -y
	add-apt-repository ppa:certbot/certbot -y
	apt-get update
fi
apt-get install python-certbot-apache -y
a2dissite 000-default.conf > /dev/null 2>&1
a2dissite acuparse.conf > /dev/null 2>&1
rm /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/default-ssl.conf  /etc/apache2/sites-enabled/acuparse.conf > /dev/null 2>&1
cp /opt/acuparse/config/acuparse.conf /etc/apache2/sites-available/ > /dev/null 2>&1
cp /opt/acuparse/config/acuparse-ssl.conf /etc/apache2/sites-available/ > /dev/null 2>&1
a2enmod rewrite > /dev/null 2>&1
a2enmod ssl > /dev/null 2>&1
a2ensite acuparse.conf > /dev/null 2>&1
a2ensite acuparse-ssl.conf > /dev/null 2>&1
systemctl stop apache2.service
sed -i "s/#ServerName/ServerName $LE_DOMAIN\n    ServerAlias www.$LE_DOMAIN/g" /etc/apache2/sites-available/acuparse-ssl.conf
certbot -n --authenticator standalone --installer apache --agree-tos --${LE_REDIRECT} --email ${LE_EMAIL} ${LE_SECURE_DOMAINS}
systemctl start apache2.service
printf "Done with Certificate Config\n"