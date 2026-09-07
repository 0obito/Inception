FROM debian:bookworm

RUN apt-get update && apt-get install -y nginx openssl && rm -rf /var/lib/apt/lists/*

# Generate the SSL certificate required by the project rubric
RUN mkdir -p /etc/nginx/ssl
RUN openssl req -x509 -nodes -out /etc/nginx/ssl/inception.crt -keyout /etc/nginx/ssl/inception.key -subj "/C=MA/ST=Casablanca/L=Casablanca/O=1337/OU=Student/CN=aelmsafe.42.fr"

COPY conf/nginx.conf /etc/nginx/nginx.conf

EXPOSE 443

# Run NGINX in the foreground so the container doesn't instantly exit
CMD ["nginx", "-g", "daemon off;"]