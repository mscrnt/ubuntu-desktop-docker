# Developer Environment Docker

This Docker container provides a ready-to-use development environment based on Ubuntu 22.04 with the following tools pre-installed:

- NVIDIA Driver 530
- OBS Studio
- Firefox
- Visual Studio Code
- Python 3.10
- OpenSSH Server
- TigerVNC
- XRDP
- VLC
- Git
- Curl
- FFMpeg
- Htop
- XFCE desktop environment

## Prerequisites

- Docker installed on your machine.
- NVIDIA Container Toolkit installed on your machine.
- cudnn-linux-x86_64-8.5.0.96_cuda11-archive.tar.xz placed next to Dockerfile.

## Getting Started

1. Pull the Docker image from Docker Hub:

```bash
docker pull mscrnt/ubuntu-desktop:latest
```

2. Run the Docker container:

Replace \<USERNAME>, \<PASSWORD>, and \<VNCPASSWORD> with the desired values.

```bash
docker run -it -p 5901:5901 -p 3389:3389 -p 22:22 -e USER=\<USERNAME> -e PASSWORD=\<PASSWORD> -e VNCPASSWORD=\<VNCPASSWORD> mscrnt/ubuntu-desktop:latest
```

3. Access the container:

- VNC: Use a VNC client to connect to \`localhost:5901\` with the VNC password you provided.
- RDP: Use a remote desktop client to connect to \`localhost:3389\` with the username and password you provided.
- SSH: Use an SSH client to connect to \`localhost:22\` with the username and password you provided.

4. Use Docker Compose file:

Create a `docker-compose.yaml` file with the following content:

```yaml
version: "3.8"
services:
  ubuntu-desktop:
    container_name: ubuntu-desktop-container
    image: mscrnt/ubuntu-desktop:latest
    environment:
      - USER=
      - PASSWORD=
      - VNCPASSWORD=
    ports:
      - "22:22"
      - "5901:5901"
      - "3389:3389"
    volumes:
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
```

Fill in the blanks in the docker-compose.yaml file:
- USER: The username for the container user 
- PASSWORD: The password for the container user .
- VNCPASSWORD: The VNC password for the container user 
