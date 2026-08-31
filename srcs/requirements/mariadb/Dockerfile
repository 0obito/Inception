FROM debian:bookworm

RUN apt-get update -y && apt-get install mariadb-server -y

RUN sed -i "s/127.0.0.1/0.0.0.0/g" /etc/mysql/mariadb.conf.d/50-server.cnf

COPY tools/mariadb_script.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/mariadb_script.sh

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/mariadb_script.sh"]
