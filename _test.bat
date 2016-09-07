@echo off
docker stop customVarnish
docker rm customVarnish
docker create -it --name customVarnish --hostname customVarnish -p 80:80 --privileged --ulimit nofile=232072 --ulimit memlock=500000 -e BACKEND_HOST=www.facebook.com -e BACKEND_PORT:80 luizcarlosfaria/varnish
docker start customVarnish
timeout 1
docker ps -a --filter "name=customVarnish"
REM docker logs customVarnish
REM docker rm customVarnish




REM docker run -p 80:80 -v c:/docker/varnish/app.config:/etc/varnish/default.vcl -v  c:/docker/varnish/process.config:/etc/default/varnish luizcarlosfaria/varnish /bin/bash


