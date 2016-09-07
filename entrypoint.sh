#!/bin/bash
set -e

if [ ! -f /etc/default/varnish ] 
then
	cp /_config_backup/process.config 				/_config_backup/process.config.tmp -R
	sed -i 's/6081/'"${VARNISH_PORT}"'/g' 			/_config_backup/process.config.tmp
	sed -i 's/256m/'"${VARNISH_MEMORY}"'/g' 			/_config_backup/process.config.tmp
	mv /_config_backup/process.config.tmp 			/etc/default/varnish
fi


if [ ! -f /etc/varnish/default.vcl ] 
then
	cp /_config_backup/app.config 					/_config_backup/app.config.tmp -R
	sed -i 's/127.0.0.1/'"${BACKEND_HOST}"'/g' 		/_config_backup/app.config.tmp
	sed -i 's/8080/'"${BACKEND_PORT}"'/g' 			/_config_backup/app.config.tmp
    mv /_config_backup/app.config.tmp 				/etc/varnish/default.vcl
fi

service varnish start

 exec "bash"
