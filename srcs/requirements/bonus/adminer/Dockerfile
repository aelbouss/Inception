FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    php-cli \
    php-mysql \
    php-pgsql \
    php-sqlite3 \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

# install the latest single file version of adminer and name it index.php
RUN rm -f index.html && curl -L https://www.adminer.org/latest.php -o index.php

EXPOSE 8080

CMD ["php", "-S", "0.0.0.0:8080"]