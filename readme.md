# `build.sh`

This interactive script builds desired images, creating local volumes as needed:

- The `burp_share` volume holds the JAR file as well as project and user configuration options.
- The `novnc_share` volume holds TLS certificates for the `novnc_client` and `novnc_server` machines.
- The `x11_socket` volume links `/tmp/.X11-unix` between the `burp` and `novnc_server` containers for GUI display.

# `run.sh`

This interactive script runs desired images according to supplied parameters.

> Note: to display `docker run` commands without executing them, issue `run.sh --print`

# Images

## `burp`
Runs Burp Suite.

### Headless mode
- If the docker host is your local machine, this image is all you need. You'll be able to access files through the local `burp_share` volume.
- If the docker host is a remote machine, you will need the `sshd` image in order to access files. The `burp_share` volume will be mounted to `~/burp_share` on the `sshd` image.

### GUI mode
- If the docker host is your local machine, *and* your local machine is running the [X server](https://en.wikipedia.org/wiki/X_Window_System) with a unix socket at `/tmp/.X11-unix/X0`, this image is all you need. Use `run.sh` to run the image, and the script will set up the necessary mounts.
- If the docker host is your local machine, *but* your local machine *is not* running the X server, you will need the `novnc_client` and `novnc_server` images. Files can be accessed through the `burp_share` and `novnc_share` volumes.
- If the docker host is a remote machine, you will need all other images. The `burp_share` and `novnc_share` volumes will be mounted to `~/burp_share` and `~/novnc_share` on the `sshd` image, respectively.

> Note: when using the `novnc_client` and `novnc_server` images, you must establish the VNC connection prior to running the `burp` image. Otherwise, the required X socket will not be available and Burp will fail to start.

## `sshd`
Runs an SSH service with volume mounts for remote file management.

Building this image requires an `authorized_keys` file containing allowed public keys for SSH connections.

The `burp_share` and `novnc_share` volumes will be mounted to `~/burp_share` and `~/novnc_share` on this image, respectively.

## `novnc_client`
Runs an Apache web server to provide a [noVNC](https://novnc.com/info.html) client.

By default, it will generate a self-signed certificate. To supply your own certificate and keys, use the `novnc_share` volume.

### Connecting to the `novnc_server` instance
1. Visit the address where `novnc_client` is running; e.g., `https://127.0.0.1:4433`.
2. Click on the settings icon (the little gear).
3. Click *Advanced* to expand that section.
4. Click *WebSocket* to expand that section.
5. Enter the address where `novnc_server` is running; e.g., `https://127.0.0.1:6080`.
6. Finally, click the *Connect* button in the middle of the page.

#### With a self-signed certificate
When using a self-signed certificate for the `novnc_server` image, you must first configure your browser to accept the certificate and proceed with the connection.

To do so, simply visit `https://127.0.0.1:6080`, replacing `127.0.0.1` and `6080` as appropriate, if your `novnc_server` instance is running remotely, or on a different socket.

Your browser will then display a warning, and provide the option to accept the self-signed certificate and proceed with the connection.

Upon doing so, you will receive an [HTTP 405](https://http.cat/405) response with the following content:
> Error response
>
> Error code 405.
>
> Message: Method Not Allowed.
>
> Error code explanation: 405 = Specified method is invalid for this resource.. 

This is expected and can be ignored. You can now follow the connection steps above.

## `novnc_server`
Runs `x11vnc` and `websockify` to provide a VNC connection over WebSockets.

By default, it will generate a self-signed certificate for `websockify`. To supply your own certificate and keys, use the `novnc_share` volume.

# Troubleshooting
To aid in troubleshooting, the `entrypoint.sh` scripts for the `burp` and `novnc_server` images accept a `--shell` parameter which causes the image to drop into `bash` upon execution.

# Licenses
While this repository is MIT-Licensed, additional licensing considerations apply for the `novnc_client` image. See its included `LICENSE.txt` file for details.

