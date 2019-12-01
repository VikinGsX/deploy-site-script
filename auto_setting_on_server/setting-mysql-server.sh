#!/bin/bash

# Check if user is root
[ $(id -u) != "0" ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; }
# Configure
MYSQL_ROOT_PASSWORD=""
MYSQL_NORMAL_USER=""
MYSQL_NORMAL_USER_PASSWORD=""

# Check if password is defined
if [[ "$MYSQL_ROOT_PASSWORD" == "" ]]; then
    echo "${CFAILURE}Error: MYSQL_ROOT_PASSWORD not define!!${CEND}";
    exit 1;
fi
if [[ "$MYSQL_NORMAL_USER_PASSWORD" == "" ]]; then
    echo "${CFAILURE}Error: MYSQL_NORMAL_USER_PASSWORD not define!!${CEND}";
    exit 1;
fi



# Install MySQL
debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password ${MYSQL_ROOT_PASSWORD}"
debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password ${MYSQL_ROOT_PASSWORD}"
apt-get install -y mysql-server
# Configure MySQL Password Lifetime
echo "default_password_lifetime = 0" >> /etc/mysql/mysql.conf.d/mysqld.cnf
mysql --user="root" --password="${MYSQL_ROOT_PASSWORD}" -e "CREATE USER '${MYSQL_NORMAL_USER}'@'0.0.0.0' IDENTIFIED BY '${MYSQL_NORMAL_USER_PASSWORD}';"
mysql --user="root" --password="${MYSQL_ROOT_PASSWORD}" -e "GRANT ALL ON *.* TO '${MYSQL_NORMAL_USER}'@'127.0.0.1' IDENTIFIED BY '${MYSQL_NORMAL_USER_PASSWORD}' WITH GRANT OPTION;"
mysql --user="root" --password="${MYSQL_ROOT_PASSWORD}" -e "GRANT ALL ON *.* TO '${MYSQL_NORMAL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_NORMAL_USER_PASSWORD}' WITH GRANT OPTION;"
mysql --user="root" --password="${MYSQL_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"
service mysql restart
# Add Timezone Support To MySQL
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql --user=root --password=${MYSQL_ROOT_PASSWORD} mysql


clear
echo "--"
echo "--"
echo "It's Done."
echo "Mysql Root Password: ${MYSQL_ROOT_PASSWORD}"
echo "Mysql Normal User: ${MYSQL_NORMAL_USER}"
echo "Mysql Normal User Password: ${MYSQL_NORMAL_USER_PASSWORD}"
echo "--"
echo "--"