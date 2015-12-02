#!/bin/bash

# gatekeeper installer for ubuntu
# this is for the new gatekeeper or gatekeeper v2
# Created 12-2-15
# Influenced by reddit's installer script
# assumes that the script is run in a directory
# structured:
# 
#~/
#   gatekeeper/
#      ub-gk-lamp-installer.sh
#      db/
#          create-bare-db.sql
#   <script generated files and directories created here>
#
# NOTE: do not run this as $ sudo sh <script> ...
#       as this invokes dash?? and has no <<< redirect
#       run as $ sudo <script> ...

###############################################################################
# Configuration
###############################################################################
# which user to install the code for; defaults to the user invoking this script
GK_USER=${GK_USER:-$SUDO_USER}

# the group to run reddit code as; must exist already
GK_GROUP=${GK_GROUP:-nogroup}

# the root directory to base the install in. must exist already
GK_HOME=${GK_HOME:-/home/$GK_USER}

# the domain that you will connect to your reddit install with.
# MUST contain a . in it somewhere as browsers won't do cookies for dotless
# domains. an IP address will suffice if nothing else is available.
GK_DOMAIN=${GK_DOMAIN:-gatekeeper.virtnet}

SERVER_NAME='gatekeeper'
VERSION='1.1'
WKGRP='HOMENET'

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

SYS_IP="`ip addr show eth0 | grep inet | awk '{ print $2; }' | sed 's/\/.*$//'`"

# DB credentials stored as env vars
# DB_ROOT_PW=$GK_DB_PW
# DB_USER=$GK_DB_USER
# DB_NAME=$GK_DB_NAME
# DB_HOST=$GK_DB_HOST
DB_ROOT_PW=$2
DB_USER=$1
DB_NAME=$3
DB_HOST=$4

###############################################################################
# Sanity Checks
###############################################################################
if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Must be run with root privileges."
    exit 1
fi

if [[ -z "$DB_ROOT_PW" ]]; then 
	echo "USAGE: <installer> <dbusername> <dbpassword> <dbname> <dbhost>"
	exit 1
fi

###############################################################################
# Install prerequisites
###############################################################################
set -x

# aptitude configuration
APTITUDE_OPTIONS="-y"
export DEBIAN_FRONTEND=noninteractive

# run an aptitude update to make sure python-software-properties
# dependencies are found
apt-get update

# install prerequisites
cat <<PACKAGES | xargs apt-get install $APTITUDE_OPTIONS
git-core
python-dev
python-setuptools
python-mysqldb
php5-common
php5-mysql
samba
phpmyadmin 
PACKAGES


sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $DB_ROOT_PW"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DB_ROOT_PW"
sudo apt-get -y install mysql-server

##############################################################################
# create filesystem shares and set permissions
##############################################################################
echo "Creating filesystem..."
mkdir -p $GK_HOME/content
mkdir -p $GK_HOME/hold
mkdir -p $GK_HOME/dropoff
mkdir -p $GK_HOME/app
mkdir -p $GK_HOME/app/bin
mkdir -p $GK_HOME/trash
mkdir -p $GK_HOME/log
mkdir -p $GK_HOME/opt

# TODO: fix this! - the sym link is problematic for now 
# ln -s $GK_HOME/app /var/www/html/applications

##############################################################################
# put the gatekeeper.sh script in place
##############################################################################
cp $DIR/gatekeeper.sh $GK_HOME/app/bin/
chmod 775 $GK_HOME/app/bin/gatekeeper.sh

# TODO: add cron entry to run this 

##############################################################################
# create mysql tables
##############################################################################
echo "Creating Database..."
mysql -u"$DB_USER" -p"$DB_ROOT_PW" -e "CREATE DATABASE $DB_NAME;"
# this is not needed but it works and it may be useful once there is a real database around
#mysql -h "$DB_HOST" -u "$DB_USER" -p "$DB_ROOT_PW" "$DB_NAME" < ./db/create-bare-db.sql

###############################################################################
# generate php test page
###############################################################################

cat > /var/www/html/info.php <<PINFO

<?php phpinfo(); ?>

PINFO

###############################################################################
# configure samba
###############################################################################
mv /etc/samba/smb.conf /etc/samba/smb.conf.bak

cat > /etc/samba/smb.conf <<SCONF
[global]
workgroup = $WKGRP
server string = Samba Server %v
netbios name = ubuntu
security = user
map to guest = bad user
dns proxy = no
#============================ Share Definitions ============================== 
[apps]
path = $GK_HOME/app
browsable =yes
writable = yes
guest ok = yes
read only = no
SCONF

service samba restart

chown -R cromaca:cromaca /var/www
chown -R cromaca:cromaca $GK_HOME

###############################################################################
# All done!
###############################################################################

cat <<CONCLUSION

******************************************************************************

Congratulations! Your $SERVER_NAME $VERSION LAMP server is now installed.

* You will need to test the mysql database

* check php status at http://$SYS_IP/info.php

******************************************************************************

CONCLUSION
