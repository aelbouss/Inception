FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    tar \
    && rm -rf /var/lib/apt/lists/*


RUN curl -sSL https://github.com/portainer/portainer/releases/download/2.19.5/portainer-2.19.5-linux-amd64.tar.gz -o portainer.tar.gz \
    && tar -xzvf portainer.tar.gz -C /usr/local \
    && rm -f portainer.tar.gz

WORKDIR /usr/local/portainer

EXPOSE 9000

CMD ["/usr/local/portainer/portainer", "--no-analytics"]