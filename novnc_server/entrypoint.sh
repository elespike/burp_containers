#! /bin/bash

_shell=""
_home="/home/oracle"

mkdir -p ${_home}/share

[[ -f ${_home}/share/websockify.pem ]] || \
    openssl req -x509 -nodes              \
    -out    ${_home}/share/websockify.pem \
    -keyout ${_home}/share/websockify.pem \
    -subj "/CN=novnc_server.$(hostname)"

passwdfile="${_home}/share/vncpass.$(hostname)"
# Generate passwords for full access and view-only access.
head -c 24 /dev/urandom | base64 >  ${passwdfile}
head -c 24 /dev/urandom | base64 >> ${passwdfile}

chmod 400 ${_home}/share/*
chown -R oracle:oracle ${_home}
chown    oracle:oracle /tmp/.X11-unix

resolution="1600x900"
while [[ -n ${1} ]]
do
    [[ ${1} =~ --[0-9]{3,4}x[0-9]{3,4} ]] && resolution=${1:2}
    [[ ${1} == "--shell" ]] && _shell="& exec /bin/bash -i"
    shift
done

export X11VNC_CREATE_GEOM=${resolution}
export DISPLAY=:20  # this is the first display attempted by "x11vnc -create"

_chroot="chroot --userspec=oracle:oracle / env HOME=${_home}"

${_chroot} websockify -D                 \
    --cert ${_home}/share/websockify.pem \
    --ssl-only 0.0.0.0:6080 127.0.0.1:5900

exec ${_chroot} /bin/bash -c "x11vnc    \
    -create -localhost -shared -forever \
    -passwdfile ${passwdfile}           \
    -afteraccept 'fluxbox &' ${_shell}"

