#! /bin/bash

# Abort on error
set -e

script_dir=${0%/*}
[[ -d ${script_dir} ]] || script_dir=$(pwd)

function create_volumes {
    while [[ -n ${1} ]]
    do
        (docker volume inspect ${1} &> /dev/null && printf "[-] Volume '${1}' already exists.\n") \
            || (docker volume create ${1} &> /dev/null && printf "[+] Created volume '${1}'!\n")
        shift
    done
}

read -p $'\n[?] Build Burp image? [y/N]\n> ' build
if [[ ${build,,} =~ ^y.* ]]
then
    create_volumes burp_share x11_socket
    docker build -t burp:latest ${script_dir}/burp
fi

read -p $'\n[?] Build SSH image for remote file access? [y/N]\n> ' build
if [[ ${build,,} =~ ^y.* ]]
then
    read -ei "${HOME}/.ssh/id_rsa.pub" -p $'\n[?] Please enter the full path of the public key file for SSH login:\n> ' key_file
    cp -f ${key_file} ${script_dir}/sshd/authorized_keys
    docker build -t sshd:latest ${script_dir}/sshd
    rm -f ${script_dir}/sshd/authorized_keys
fi

read -p $'\n[?] Build VNC images for remote GUI display? [y/N]\n> ' build
if [[ ${build,,} =~ ^y.* ]]
then
    create_volumes novnc_share
    docker build -t novnc_client:latest ${script_dir}/novnc_client
    docker build -t novnc_server:latest ${script_dir}/novnc_server
fi

printf "\n[+] Done!\n"

