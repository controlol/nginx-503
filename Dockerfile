FROM nginx:alpine
LABEL maintainer "Luc Appelman lucapppelman@gmail.com"

ADD root /

WORKDIR /etc/nginx
