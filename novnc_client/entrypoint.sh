#! /bin/bash

mkdir -p ${HOME}/share

[[ -f ${HOME}/share/novnc_client.crt && -f ${HOME}/share/novnc_client.key ]] || \
    openssl req -x509 -nodes               \
    -out    ${HOME}/share/novnc_client.crt \
    -keyout ${HOME}/share/novnc_client.key \
    -subj "/CN=novnc_client.$(hostname)"

chmod 400 ${HOME}/share/*
chown -R 1000:1000 ${HOME}/share

cp -s ${HOME}/share/novnc_client.crt /usr/local/apache2/conf/server.crt
cp -s ${HOME}/share/novnc_client.key /usr/local/apache2/conf/server.key

# Enable TLS, per https://hub.docker.com/_/apache2.
sed -i                                                 \
    -e 's/^#\(Include .*httpd-ssl.conf\)/\1/'          \
    -e 's/^#\(LoadModule .*mod_ssl.so\)/\1/'           \
    -e 's/^#\(LoadModule .*mod_socache_shmcb.so\)/\1/' \
    /usr/local/apache2/conf/httpd.conf

exec /usr/local/bin/httpd-foreground

