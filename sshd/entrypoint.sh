#! /bin/bash

_home="/home/scribe"

mkdir -p ${_home}/burp_share/user_configs
mkdir -p ${_home}/burp_share/project_configs
mkdir -p ${_home}/novnc_share

chown -R scribe:scribe ${_home}

exec /usr/sbin/sshd -D

