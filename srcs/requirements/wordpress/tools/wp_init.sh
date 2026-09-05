
# create php runtime 

WEB_ROOT="/var/www/html"

mkdir -p /run/php

chown www-data:www-data /run/php


# the  initialization guard
    
if [! "$WEB_ROOT/wp-config.php"]; then
    # automatically generate a config using our environment variables
    wp-cli config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="${MYSQL_HOST}" ;
    # install the  wordpress core  which are the wodpress actual files
   wp-cli core install \
       --url="${WP_URL}" \
       --title="${WP_TITLE}" \
       --admin_user="${WP_ADMIN_USER}" \
       --admin_pasword="${WP_ADMIN_PASSWORD}" \
       --admin_email="${WP_ADMIN_EMAIL}" ;
   # create a  secondary user
   wp-cli user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
         --role=author \
         --user_pass ="${WP_USER_PASSWORD}" ;

    chown -R www-data:www-data /var/www/html
fi

exec php-fpm -F

