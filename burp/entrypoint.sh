#! /bin/bash

_shell=""
_home="/home/burp"

headless="-Djava.awt.headless=true"
default_project_json="${_home}/share/project_configs/headless.json"
default_user_json="${_home}/share/user_configs/headless.json"
url="https://portswigger.net/burp/releases/download?product=community&type=jar"

while [[ -n ${1} ]]
do
    arg_name=${1%%=*}
    arg_value=${1#*=}
    if [[ ${arg_name} == "--gui" ]]
    then
        headless="-Djava.awt.headless=false"
        default_project_json="${_home}/share/project_configs/gui.json"
        default_user_json="${_home}/share/user_configs/gui.json"
        # This is the first display attempted by "x11vnc -create",
        # which is what the "novnc_server" container uses.
        export DISPLAY=:20
    fi
    [[ ${arg_name} == "--url" ]] && url=${arg_value}
    [[ ${arg_name} == "--user" && -n ${arg_value} ]] && user_json=${arg_value}
    [[ ${arg_name} == "--proj" && -n ${arg_value} ]] && project_json=${arg_value}
    [[ ${arg_name} == "--shell" ]] && _shell="& exec /bin/bash -i"
    shift
done

[[ -z ${user_json} ]] && user_json=${default_user_json}
[[ -z ${project_json} ]] && project_json=${default_project_json}

mkdir -p ${_home}/share/user_configs
mkdir -p ${_home}/share/project_configs

cp -n ${_home}/user_configs/*    ${_home}/share/user_configs/
cp -n ${_home}/project_configs/* ${_home}/share/project_configs/

jar_file="${_home}/share/burpsuite.jar"
[[ -f ${jar_file} ]] || wget ${url} -O ${jar_file}

chown -R burp:burp ${_home}

java_cmd="java ${headless} -jar ${jar_file} --user-config-file=${user_json} --config-file=${project_json}"

exec chroot --userspec=burp:burp / env HOME=${_home} /bin/bash -c "${java_cmd} ${_shell}"

