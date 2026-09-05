FROM debian:bookworm

RUN apt-get update && apt-get install -y php8.2-fpm php8.2-mysql php8.2-curl php8.2-gd \
  php8.2-intl php8.2-mbstring php8.2-soap php8.2-xml php8.2-zip wget curl mariadb-client \
  && ln -s /usr/sbin/php-fpm8.2 /usr/local/bin/php-fpm \
  && rm -rf /var/lib/apt/lists/*

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# WORKDIR /var/www/html

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/
COPY tools/script_wp.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/script_wp.sh

EXPOSE 9000

ENTRYPOINT ["script_wp.sh"]