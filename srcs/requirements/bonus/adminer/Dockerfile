FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    php \
    php-cli \
    php-mysql \
    php-pgsql \
    php-sqlite3 \
    wget \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y curl

WORKDIR /var/www/html

# install the  latest single file verion of  adminer and name it  index.php
RUN curl -L https://www.adminer.org/latest.php -o index.php

EXPOSE 8080

CMD ["php", "-S", "0.0.0.0:8080"]