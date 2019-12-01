#!/bin/bash

# check import config
colorPath = "/color-config.sh"
if[! -d colorPath]
then
echo "${CFAILURE}錯誤: ${colorPath}檔案不存在!!! ${CEND}";
exit 1;
else
source ./color-config
fi

echo "********************************************************"
echo "${CTITLE}【 Laravel 環境系統安裝 】 ${CEND}"
echo ""
echo " Ubuntu16.04/Nginx/Mysql "
echo "********************************************************"
sleep 5s


# apt-get 安裝期間不會出現對話框
export DEBIAN_FRONTEND=noninteractive

# Check if user is root
[ $(id -u) != "0" ] && { echo "${CFAILURE}錯誤: 使用者必須為root!! ${CEND}"; exit 1; }

if [  $(id -u) != "0" ]
then 
    echo "當前使用者並非root,正在切換為root..."
    sudo su
    sleep 2s
else
    echo "已經是root,準備進行設定系統....."
fi


# Force Locale
export LC_ALL="zh_TW.UTF-8"
echo "LC_ALL=zh_TW.UTF-8" >> /etc/default/locale
locale-gen zh_TW.UTF-8


# Add www user and group
# addgroup www
# useradd -g www -d /home/www -c "www data" -m -s /usr/sbin/nologin www

# Update Package List
apt-get update
# Update System Packages
apt-get -y upgrade

echo "${CYELLOW} 刪除Apache... ${CEND}";
# remove apache2
apt-get purge apache2 -y

# PPAs 管理套件
apt-get install -y software-properties-common

# 新增ppa來源
apt-add-repository ppa:nginx/development -y
apt-add-repository ppa:chris-lea/redis-server -y
apt-add-repository ppa:ondrej/php -y

# Update Package Lists
apt-get update

echo "********************************************************"
echo "【 安裝設定PHP相關擴展 】"
echo "********************************************************"
sleep 2s

# Install PHP	
apt-get install -y \
php7.2 \
php7.2-mysql \
php7.2-fpm \
php7.2-curl \
php7.2-xml \
php7.2-json \
php7.2-gd \
php7.2-mbstring \
php7.2-bcmath \


# php7.2-cli php7.2-dev \
# php7.2-memcached \
# php7.2-imap  \
#  php7.2-zip php7.2-soap \
# php7.2-intl php7.2-readline \
# php-xdebug php-pear


# Setup Some PHP-FPM Options
sed -i "s/error_reporting = .*/error_reporting = E_ALL \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED/" /etc/php/7.2/fpm/php.ini
sed -i "s/display_errors = .*/display_errors = Off/" /etc/php/7.2/fpm/php.ini
sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.2/fpm/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.2/fpm/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 50M/" /etc/php/7.2/fpm/php.ini
sed -i "s/post_max_size = .*/post_max_size = 50M/" /etc/php/7.2/fpm/php.ini
sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.2/fpm/php.ini
# sed -i "s/listen =.*/listen = /var/run/php7.2-fpm.sock/" /etc/php/7.2/fpm/pool.d/www.conf
# sed -i "s/listen =.*/listen = 127.0.0.1:9000/" /etc/php/7.2/fpm/pool.d/www.conf

# Set PHP-FPM User
sed -i "s/user = www-data/user = www/" /etc/php/7.2/fpm/pool.d/www.conf
sed -i "s/group = www-data/group = www/" /etc/php/7.2/fpm/pool.d/www.conf
sed -i "s/listen\.owner.*/listen.owner = www/" /etc/php/7.2/fpm/pool.d/www.conf
sed -i "s/listen\.group.*/listen.group = www/" /etc/php/7.2/fpm/pool.d/www.conf
sed -i "s/;listen\.mode.*/listen.mode = 0666/" /etc/php/7.2/fpm/pool.d/www.conf

echo "--------------------------------------------------------"
echo "${CYELLOW}PHP相關設定完畢!!!${CEND}"
echo "--------------------------------------------------------"
seepl 3s



# Install Nginx
apt-get install -y --force-yes nginx

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

# Set The Nginx
sed -i "s/user www-data;/user www;/" /etc/nginx/nginx.conf
sed -i "s/# server_names_hash_bucket_size.*/server_names_hash_bucket_size 64;/" /etc/nginx/nginx.conf


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

# Install Composer
apt-get install -y composer

# Add Composer Global Bin To Path
printf "\nPATH=\"$(composer config -g home 2>/dev/null)/vendor/bin:\$PATH\"\n" | tee -a ~/.profile
echo "--------------------------------------------------------"
echo "Composer version:" $(composer -V)
echo "--------------------------------------------------------"
seepl 3s

# Install Node 
curl --silent --location https://deb.nodesource.com/setup_12.x | bash -
apt-get install -y nodejs
apt-get install -y npm
echo "--------------------------------------------------------"
echo -n "${CYELLOW}Node.js安裝版本為:${CEND}" $(node -v)
echo "${CYELLOW}/ Npm版本為:${CEND}" $(npm -v)
echo "--------------------------------------------------------"
seelp 3s


# Install Some Basic Packages
# apt-get install -y build-essential dos2unix gcc git libmcrypt4 libpcre3-dev \
# make python2.7-dev python-pip re2c supervisor unattended-upgrades whois vim libnotify-bin
# Set My Timezone
# ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime


# install apt package
apt-get -y install zsh htop zip unzip

# install other npm package
/usr/bin/npm install -g bower
/usr/bin/npm install -g gulp-cli
/usr/bin/npm install -g yarn
/usr/bin/npm install -g grunt-cli

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
echo "--"
echo "--"
