FROM ubuntu:14.04
MAINTAINER Luiz Carlos Faria

# Set the env variable DEBIAN_FRONTEND to noninteractive
ENV DEBIAN_FRONTEND noninteractive

ENV BACKEND_HOST BACKEND_HOST
ENV BACKEND_PORT 80

ENV VARNISH_PORT 80
ENV VARNISH_MEMORY 2048m

# Fix locales
RUN locale-gen en_US.UTF-8 && dpkg-reconfigure locales

WORKDIR /home

RUN apt-get -y update \
&& apt-get -y install apt-transport-https curl wget nano htop \
&& curl https://repo.varnish-cache.org/GPG-key.txt | apt-key add - \
&& echo "deb https://repo.varnish-cache.org/ubuntu/ trusty varnish-4.1" >> /etc/apt/sources.list.d/varnish-cache.list \
&& apt-get -y update && apt-get -y install varnish

RUN service varnish stop
RUN echo 1

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh \
&& mkdir /_config_backup/ \
&& mv /etc/default/varnish /_config_backup/process.config \
&& mv /etc/varnish/default.vcl /_config_backup/app.config


EXPOSE 80

VOLUME /etc/varnish
VOLUME /etc/default

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]