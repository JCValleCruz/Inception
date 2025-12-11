#!/bin/bash

cd /var/www/html

if [ ! -f wp-config.php ]; then
    echo "Setting up WordPress..."

    MYSQL_PASSWORD=$(cat /run/secrets/db_password)

    while ! mysqladmin ping -h"${WORDPRESS_DB_HOST%:*}" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent; do
        echo "Waiting for MariaDB..."
        sleep 2
    done

    wp core download --allow-root

    wp config create \
        --dbname="${WORDPRESS_DB_NAME}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="${WORDPRESS_DB_HOST}" \
        --allow-root

    wp core install \
        --url="https://${DOMAIN_NAME}" \
        --title="Inception" \
        --admin_user="${WORDPRESS_ADMIN_USER}" \
        --admin_password="$(cat /run/secrets/credentials | grep WORDPRESS_ADMIN_PASSWORD | cut -d'=' -f2)" \
        --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
        --allow-root

    wp user create "${WORDPRESS_USER}" "${WORDPRESS_USER_EMAIL}" \
        --role=author \
        --allow-root

    chown -R www-data:www-data /var/www/html
    chmod -R 755 /var/www/html

    echo "WordPress setup completed."
else
    echo "WordPress already configured."
fi

exec /usr/sbin/php-fpm7.4 -F
