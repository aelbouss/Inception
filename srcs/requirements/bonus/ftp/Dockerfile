FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    vsftpd \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/run/vsftpd/empty

EXPOSE 21 30000-30009

COPY ./conf/vsftpd.conf /etc/vsftpd.conf
COPY ./tools/ftp_init.sh /usr/local/bin/ftp_init.sh

RUN chmod +x /usr/local/bin/ftp_init.sh

ENTRYPOINT ["/usr/local/bin/ftp_init.sh"]

CMD ["/usr/sbin/vsftpd", "/etc/vsftpd.conf"]
