# initialize the base image 
FROM debian:bookworm 

# install nginx

RUN apt-get update && \
    apt-get install -y nginx \
    && rm -rf /var/lib/apt/lists/*

# install openssl for secure connection 

RUN apt-get update && \
    apt-get install -y openssl \
    && rm -rf /var/lib/apt/lists/*

# define the port that nginx will use during runtime 

EXPOSE 443

# copy my own nginx config file to the config file that nginx use 

COPY conf/nginx.conf  /etc/nginx/nginx.conf

# copy the  script that creates  the certificate

COPY tools/nginx_certif.sh /entrypoint.sh

# add the  execution permession to the  script that creates  the  cetificate

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
# select the command will be executed in runtime

CMD ["nginx", "-g" , "daemon off;"]
