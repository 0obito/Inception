#!/bin/bash

# Check if the database folder already exists in the permanent volume
if [ -d "/var/lib/mysql/${MYSQL_DATABASE}" ]
then 
    echo "Database already initialized, skipping setup..."
else
    echo "First boot detected. Initializing database..."
    service mariadb start
    sleep 2

    mysql -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;"
    mysql -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
    mysql -e "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';"
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"
    mysql -e "FLUSH PRIVILEGES;"

    mysqladmin -u root -p$MYSQL_ROOT_PASSWORD shutdown
fi

# Start MariaDB in the foreground (PID 1)
exec mysqld_safe
