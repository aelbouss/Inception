FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    php-fpm \
    php-cli \
    php-mysql \
    php-curl \
    mariadb-client \
    php-gd \
    php-mbstring \
    php-xml \
    php-zip \
    php-redis \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl  && rm -rf /var/lib/apt/lists/*


# change the config file  of the php-fpm  pool 

COPY conf/pool.conf /etc/php/8.2/fpm/pool.d/www.conf

# wordpres setup

WORKDIR /var/www/html

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

COPY  tools/wp_init.sh /usr/bin/wp_init.sh

RUN chmod +x /usr/bin/wp_init.sh

EXPOSE  9000

ENTRYPOINT ["/usr/bin/wp_init.sh"]

