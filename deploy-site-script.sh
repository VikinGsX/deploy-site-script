
# apt-get 安裝期間不會出現對話框
export DEBIAN_FRONTEND=noninteractive

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
# Force Locale
export LC_ALL="en_US.UTF-8"
echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale
locale-gen en_US.UTF-8
# Add www user and group
addgroup www
useradd -g www -d /home/www -c "www data" -m -s /usr/sbin/nologin www
# Update Package List
apt-get update
# Update System Packages
apt-get -y upgrade
# remove apache2
apt-get purge apache2 -y
# Install Some PPAs
apt-get install -y software-properties-common curl
apt-add-repository ppa:nginx/development -y
apt-add-repository ppa:chris-lea/redis-server -y
apt-add-repository ppa:ondrej/php -y

# Using the default Ubuntu 16 MySQL 7 Build
# gpg: key 5072E1F5: public key "MySQL Release Engineering <mysql-build@oss.oracle.com>" imported
# apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 5072E1F5
# sh -c 'echo "deb http://repo.mysql.com/apt/ubuntu/ xenial mysql-5.7" >> /etc/apt/sources.list.d/mysql.list'
curl --silent --location https://deb.nodesource.com/setup_6.x | bash -
# Update Package Lists
apt-get update
# Install Some Basic Packages
apt-get install -y build-essential dos2unix gcc git libmcrypt4 libpcre3-dev \
make python2.7-dev python-pip re2c supervisor unattended-upgrades whois vim libnotify-bin
# Set My Timezone
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# Install PHP Stuffs
# Current PHP	
apt-get install -y --allow-downgrades --allow-remove-essential --allow-change-held-packages \
php7.2-cli php7.2-dev \
php7.2-pgsql php7.2-sqlite3 php7.2-gd \
php7.2-curl php7.2-memcached \
php7.2-imap php7.2-mysql php7.2-mbstring \
php7.2-xml php7.2-zip php7.2-bcmath php7.2-soap \
php7.2-intl php7.2-readline \
php-xdebug php-pear


# Install Composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Add Composer Global Bin To Path
printf "\nPATH=\"$(composer config -g home 2>/dev/null)/vendor/bin:\$PATH\"\n" | tee -a ~/.profile

# Set Some PHP CLI Settings
sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.1/cli/php.ini
sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.1/cli/php.ini
sudo sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.1/cli/php.ini
sudo sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.1/cli/php.ini

# Install Nginx & PHP-FPM
apt-get install -y --force-yes nginx php7.2-fpm

# Setup Some PHP-FPM Options
sed -i "s/error_reporting = .*/error_reporting = E_ALL \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED/" /etc/php/7.2/fpm/php.ini
sed -i "s/display_errors = .*/display_errors = Off/" /etc/php/7.2/fpm/php.ini
sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.2/fpm/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.2/fpm/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 50M/" /etc/php/7.2/fpm/php.ini
sed -i "s/post_max_size = .*/post_max_size = 50M/" /etc/php/7.2/fpm/php.ini
sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.2/fpm/php.ini
#sed -i "s/listen =.*/listen = /var/run/php7.2-fpm.sock/" /etc/php/7.2/fpm/pool.d/www.conf
# sed -i "s/listen =.*/listen = 127.0.0.1:9000/" /etc/php/7.2/fpm/pool.d/www.conf

# Setup Some fastcgi_params Options
cat > /etc/nginx/fastcgi_params << EOF
fastcgi_param	QUERY_STRING		\$query_string;
fastcgi_param	REQUEST_METHOD		\$request_method;
fastcgi_param	CONTENT_TYPE		\$content_type;
fastcgi_param	CONTENT_LENGTH		\$content_length;
fastcgi_param	SCRIPT_FILENAME		\$request_filename;
fastcgi_param	SCRIPT_NAME		\$fastcgi_script_name;
fastcgi_param	REQUEST_URI		\$request_uri;
fastcgi_param	DOCUMENT_URI		\$document_uri;
fastcgi_param	DOCUMENT_ROOT		\$document_root;
fastcgi_param	SERVER_PROTOCOL		\$server_protocol;
fastcgi_param	GATEWAY_INTERFACE	CGI/1.1;
fastcgi_param	SERVER_SOFTWARE		nginx/\$nginx_version;
fastcgi_param	REMOTE_ADDR		\$remote_addr;
fastcgi_param	REMOTE_PORT		\$remote_port;
fastcgi_param	SERVER_ADDR		\$server_addr;
fastcgi_param	SERVER_PORT		\$server_port;
fastcgi_param	SERVER_NAME		\$server_name;
fastcgi_param	HTTPS			\$https if_not_empty;
fastcgi_param	REDIRECT_STATUS		200;
EOF

# Set The Nginx & PHP-FPM User
sed -i "s/user www-data;/user www;/" /etc/nginx/nginx.conf
sed -i "s/# server_names_hash_bucket_size.*/server_names_hash_bucket_size 64;/" /etc/nginx/nginx.conf
sed -i "s/user = www-data/user = www/" /etc/php/7.2/fpm/pool.d/www.conf
sed -i "s/group = www-data/group = www/" /etc/php/7.2/fpm/pool.d/www.conf
sed -i "s/listen\.owner.*/listen.owner = www/" /etc/php/7.2/fpm/pool.d/www.conf
sed -i "s/listen\.group.*/listen.group = www/" /etc/php/7.2/fpm/pool.d/www.conf
sed -i "s/;listen\.mode.*/listen.mode = 0666/" /etc/php/7.2/fpm/pool.d/www.conf

rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default

cat >  /etc/nginx/sites-available/default << EOF

# my nginx setting
server {

    listen 80 default_server;
    listen [::]:80 default_server ipv6only=on;

    server_name your_site;
    root /var/www/your_site_folder/public;

    
    # 防止人家iframe你的網站
            add_header X-Frame-Options "SAMEORIGIN";
       
    # 防止跨站脚本 Cross-site scripting (XSS) ，目前已经被大多数浏览器支持
          add_header X-XSS-Protection "1; mode=block";

    # 通过下面这个响应头可以禁用浏览器的类型猜测行为
            add_header X-Content-Type-Options "nosniff";



    index index.php index.html index.htm;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }


        location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt { access_log off; log_not_found off; }

        
        error_page 404 /index.php;


    location ~ \.php$ {

        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php7.2-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }


    location ~ /\.(?!well-known).* { 
       deny all;
    }



}

EOF

service nginx restart
service php7.2-fpm restart

# Install Node
apt-get install -y nodejs
/usr/bin/npm install -g bower
/usr/bin/npm install -g gulp-cli
/usr/bin/npm install -g yarn
/usr/bin/npm install -g grunt-cli

# Install SQLite
# apt-get install -y sqlite3 libsqlite3-dev



# Install MySQL
#echo "mysql-server mysql-server/root_password password secret" | debconf-set-selections
#echo "mysql-server mysql-server/root_password_again password secret" | debconf-set-selections
#apt-get install -y mysql-server
# Configure MySQL Password Lifetime
#echo "default_password_lifetime = 0" >> /etc/mysql/mysql.conf.d/mysqld.cnf
# Configure MySQL Remote Access
#sed -i '/^bind-address/s/bind-address.*=.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
#mysql --user="root" --password="secret" -e "GRANT ALL ON *.* TO root@'0.0.0.0' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
#service mysql restart
#mysql --user="root" --password="secret" -e "CREATE USER 'homestead'@'0.0.0.0' IDENTIFIED BY 'secret';"
#mysql --user="root" --password="secret" -e "GRANT ALL ON *.* TO 'homestead'@'0.0.0.0' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
#mysql --user="root" --password="secret" -e "GRANT ALL ON *.* TO 'homestead'@'%' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
#mysql --user="root" --password="secret" -e "FLUSH PRIVILEGES;"
#mysql --user="root" --password="secret" -e "CREATE DATABASE homestead character set UTF8mb4 collate utf8mb4_bin;"
#service mysql restart
# Add Timezone Support To MySQL
#mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql --user=root --password=secret mysql


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

# apt-get install MariaDB -y
# apt-get install mariadb-server mariadb-client -y


# Install A Few Other Things
apt-get install -y redis-server memcached beanstalkd
# Configure Supervisor
systemctl enable supervisor.service
service supervisor start
# Configure Beanstalkd
sed -i "s/#START=yes/START=yes/" /etc/default/beanstalkd
/etc/init.d/beanstalkd start
# Enable Swap Memory
/bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=1024
/sbin/mkswap /var/swap.1
/sbin/swapon /var/swap.1
clear
echo "--"
echo "--"
echo "It's Done."
echo "Mysql Root Password: ${MYSQL_ROOT_PASSWORD}"
echo "Mysql Normal User: ${MYSQL_NORMAL_USER}"
echo "Mysql Normal User Password: ${MYSQL_NORMAL_USER_PASSWORD}"
echo "--"
echo "--"
