
# Developer Environment Docker

This Docker container provides a ready-to-use development environment based on Ubuntu 22.04 with the following tools pre-installed:

- OBS Studio
- Chrome
- Visual Studio Code
- Python 3.10
- OpenSSH Server
- TigerVNC
- XRDP
- X2Go
- VLC
- Git
- Curl
- FFMpeg
- Htop
- XFCE desktop environment

## Prerequisites

- Docker installed on your machine.

## Getting Started

1. **Pull the Docker image from Docker Hub:**

```bash
docker pull mscrnt/ubuntu-desktop:headless
```

2. **Run the Docker container:**

Replace `<USERNAME>`, `<PASSWORD>`, `<VNCPASSWORD>`, `<ENABLE_X2GO>`, `<ENABLE_VNC>`, and `<ENABLE_XRDP>` with the desired values.

```bash
docker run --privileged -it -p 5901:5901 -p 3389:3389 -p 22:22 -e USER=<USERNAME> -e PASSWORD=<PASSWORD> -e VNCPASSWORD=<VNCPASSWORD> -e ENABLE_X2GO=<ENABLE_X2GO> -e ENABLE_VNC=<ENABLE_VNC> -e ENABLE_XRDP=<ENABLE_XRDP> your_image_name:latest
```

3. **Access the container:**

- **VNC**: Use a VNC client to connect to `localhost:5901` with the VNC password you provided.
- **RDP**: Use a remote desktop client to connect to `localhost:3389` with the username and password you provided.
- **SSH**: Use an SSH client to connect to `localhost:22` with the username and password you provided.
  
4. **Use Docker Compose file:**

Create a `docker-compose.yaml` file with the following content:

```yaml
version: "3.8"
services:
  ubuntu-desktop:
    container_name: ubuntu-desktop-headless
    image: mscrnt/ubuntu-desktop:headless
    environment:
      - USER=
      - PASSWORD=
      - VNCPASSWORD=
      - ENABLE_X2GO=
      - ENABLE_VNC=
      - ENABLE_XRDP=
    ports:
      - "22:22"
      - "5901:5901"
      - "3389:3389"
```

Fill in the blanks in the docker-compose.yaml file:
- `USER`: The username for the container user.
- `PASSWORD`: The password for the container user.
- `VNCPASSWORD`: The VNC password for the container user.
- `ENABLE_X2GO`: Set to "true" to enable X2Go, otherwise leave blank.
- `ENABLE_VNC`: Set to "true" to enable VNC, otherwise leave blank.
- `ENABLE_XRDP`: Set to "true" to enable XRDP, otherwise leave blank.
