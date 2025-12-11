#!/bin/bash

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB database..."

    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
    MYSQL_PASSWORD=$(cat /run/secrets/db_password)

    mysqld --user=mysql --bootstrap << EOF
USE mysql;
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

    echo "MariaDB database initialized successfully."
else
    echo "MariaDB database already exists."
fi

exec mysqld --user=mysql --console
