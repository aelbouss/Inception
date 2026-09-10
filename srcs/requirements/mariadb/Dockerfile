FROM debian:bookworm

RUN apt-get update && apt-get install -y mariadb-server \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/mysql/*

VOLUME ["/var/lib/mysql"]

COPY ./conf/50-server.conf /etc/mysql/mariadb.conf.d/50-server.cnf

COPY ./tools/db-initializer.sh /usr/local/bin/db-initializer.sh

RUN chmod +x /usr/local/bin/db-initializer.sh

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/db-initializer.sh"]

