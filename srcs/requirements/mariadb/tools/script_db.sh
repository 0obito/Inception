#!/bin/bash

#set -eu
set -e

DATADIR="/var/lib/mysql"

echo "starting mariaDB initialization script..."

if [ ! -d "$DATADIR/mysql" ]; then
	echo "initializing data directory..."
	mysql_install_db --user=mysql --datadir=$DATADIR > /dev/null
fi

echo "starting temporary mariaDB server for setup..."

mysqld --skip-networking --socket=/run/mysqld/mysqld.sock --user=mysql & pid="$!"

until mysqladmin --socket=/run/mysqld/mysqld.sock ping >/dev/null 2>&1; do
    sleep 1
done
echo "server's ready for setup."

echo "starting setup..."
mysql --socket=/run/mysqld/mysqld.sock -u root << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

echo "stopping temporary mariaDB server..."
mysqladmin --socket=/run/mysqld/mysqld.sock -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown

wait "$pid" || true

exec mysqld --user=mysql --datadir=$DATADIR --socket=/run/mysqld/mysqld.sock
