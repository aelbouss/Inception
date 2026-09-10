FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    redis-server \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /data  && chown redis:redis /data 

RUN mkdir -p etc/redis && chown redis:redis /etc/redis

USER redis

WORKDIR /data

COPY conf/redis.conf /etc/redis/redis.conf

EXPOSE 6379

CMD ["redis-server", "/etc/redis/redis.conf"]