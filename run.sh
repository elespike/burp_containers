#! /bin/bash

read -p $'\n[?] Run new instance of SSH image for remote file access? [y/N]\n> ' answer
if [[ ${answer,,} =~ ^y.* ]]
then
    read -ei "0.0.0.0:2200" -p $'\n[?] Which socket to expose on the host machine?\n> ' sshd_socket
    run_sshd_cmd="docker run -d -it --rm \
        --mount src=burp_share,dst=/home/scribe/burp_share,ro=false \
        --mount src=novnc_share,dst=/home/scribe/novnc_share,ro=false \
        -p ${sshd_socket}:22/tcp sshd:latest"

    printf "\n${run_sshd_cmd}\n" | tr -s ' '
    [[ ${1} == "--print" ]] || ${run_sshd_cmd}
fi

read -p $'\n[?] Run new instances of VNC images for remote GUI display? [y/N]\n> ' answer
if [[ ${answer,,} =~ ^y.* ]]
then
    read -ei "0.0.0.0:4433" -p $'\n[?] Which socket to expose on the host machine for the VNC client?\n> ' novnc_client_socket

    read -p "
[!] The default TLS certificate for the VNC client is self-signed.
    You can use your own certificate and key by adding them
    to the novnc_share docker volume as 'novnc_client.crt' and 'novnc_client.key',
    or by connecting to the SSH instance and writing them to
    '~/novnc_share/novnc_client.crt' and '~/novnc_share/novnc_client.key'.
    (Hit Enter when ready)
"
    run_novnc_client_cmd="docker run -d -it --rm \
        --mount src=novnc_share,dst=/root/share,ro=false \
        -p ${novnc_client_socket}:443/tcp novnc_client:latest"

    printf "${run_novnc_client_cmd}\n" | tr -s ' '
    [[ ${1} == "--print" ]] || ${run_novnc_client_cmd}

    read -ei "0.0.0.0:6080" -p $'\n[?] Which socket to expose on the host machine for the VNC server?\n> ' novnc_server_socket

    read -ei "1600x900" -p $'\n[?] Desired display resolution of the VNC server?\n> ' resolution

    read -p "
[!] The default TLS certificate for the VNC server is self-signed.
    You can use your own certificate and private key by adding them
    to the novnc_share docker volume as a single file called 'websockify.pem',
    or by connecting to the SSH instance and writing it to '~/novnc_share/websockify.pem'.
    (Hit Enter when ready)
"
    run_novnc_server_cmd="docker run -d -it --rm \
        --mount src=novnc_share,dst=/home/oracle/share,ro=false \
        --mount src=x11_socket,dst=/tmp/.X11-unix,ro=false \
        -p ${novnc_server_socket}:6080/tcp novnc_server:latest --${resolution}"

    printf "${run_novnc_server_cmd}\n" | tr -s ' '
    [[ ${1} == "--print" ]] || ${run_novnc_server_cmd}
fi

burp_args=()
read -p $'\n[?] Run new instance of Burp image? [y/N]\n> ' answer
if [[ ${answer,,} =~ ^y.* ]]
then
    read -ei "0.0.0.0:8080" -p $'\n[?] Which socket to expose on the host machine?\n> ' burp_socket

    json_file="headless.json"
    x11_mount="--mount src=x11_socket,dst=/tmp/.X11-unix,ro=true"

    read -p $'\n[?] Run Burp in GUI mode? [y/N]\n> ' answer
    if [[ ${answer,,} =~ ^y.* ]]
    then
        burp_args+=("--gui")
        json_file="gui.json"
        [[ -S /tmp/.X11-unix/X0 ]] && read -p $'\n[?] Use your own X Server to display Burp\'s GUI? [Y/n]\n> ' answer
        [[ ${answer,,} =~ ^n.* ]] || x11_mount="--mount type=bind,src=/tmp/.X11-unix/X0,dst=/tmp/.X11-unix/X20,ro=true"
    fi

    printf "\n[*] Custom configuration files can be written to the Burp instance
    by connecting to the SSH instance and writing them under the directories
    '~/burp_share/project_configs/' and '~/burp_share/user_configs/',
    or by adding them to the burp_share docker volume under those directories."
    read -ei ${json_file} -p $'\n[?] Which Burp user configuration file to load?\n> ' json_file
    burp_args+=("--user=/home/burp/share/user_configs/${json_file}")
    read -ei ${json_file} -p $'[?] Which Burp project configuration file to load?\n> ' json_file
    burp_args+=("--proj=/home/burp/share/project_configs/${json_file}")

    burp_url="https://portswigger.net/burp/releases/download?product=community&type=jar"
    printf "\n[*] You can supply a specific Burp JAR file
    by adding it to the burp_share docker volume as 'burpsuite.jar',
    or by connecting to the SSH instance and writing it to '~/burp_share/burpsuite.jar'."
    read -ei ${burp_url} -p $'\n[?] If no JAR file already exists, from which URL to download it?\n> ' burp_url
    burp_args+=("--url=${burp_url}")

    run_burp_cmd="docker run -d -it --rm ${x11_mount} \
        --mount src=burp_share,dst=/home/burp/share,ro=false \
        -p ${burp_socket}:8080/tcp burp:latest ${burp_args[@]}"

    printf "\n${run_burp_cmd}\n" | tr -s ' '
    [[ ${1} == "--print" ]] || ${run_burp_cmd}
fi

printf "\n[+] Done!\n"
