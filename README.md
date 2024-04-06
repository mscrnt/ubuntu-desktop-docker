# Developer Environment Docker

This Docker container provides a fully-equipped development environment built upon Ubuntu 22.04 LTS. It comes loaded with a comprehensive suite of development tools and services, orchestrated under systemd as PID 1, without the need for privileged mode. This configuration upholds the principle of least privilege, enhancing security while ensuring compatibility with services and applications that depend on systemd's management capabilities. By avoiding privileged mode, this setup maintains the container's isolation and security, making it an ideal choice for development work within a contained environment.

## Features

The container comes pre-loaded with the following tools and services:

- **OBS Studio**: For screen recording and live streaming.
- **Google Chrome**: A web browser for testing and development.
- **Visual Studio Code**: A source-code editor by Microsoft.
- **Python 3.10**: Programming language, along with `venv` and `dev` packages.
- **OpenSSH Server**: For secure access to the container over SSH.
- **TigerVNC Server**: A high-performance, open-source VNC server.
- **XRDP**: Open-source Remote Desktop Protocol server.
- **X2Go Server**: Remote desktop software for Linux.
- **VLC Media Player**: For media playback.
- **Git**: Version control system for tracking changes in source code.
- **Curl**: Command line tool and library for transferring data with URLs.
- **FFmpeg**: A complete, cross-platform solution to record, convert and stream audio and video.
- **Htop**: An interactive process viewer for Unix systems.
- **XFCE Desktop Environment**: A lightweight and modular desktop environment.

## Prerequisites

Before getting started, ensure you have Docker installed on your machine. If not, visit [Docker's official website](https://docs.docker.com/get-docker/) for installation instructions.

## Getting Started

### 1. Pull the Docker Image

To begin, pull the Docker image from Docker Hub:

```bash
docker pull mscrnt/ubuntu-desktop:headless
```

### 2. Run the Docker Container

Launch the Docker container using the following command. Be sure to replace placeholder values with your desired configuration:

```bash
docker run -d \
  --tmpfs /tmp \
  --tmpfs /run \
  --tmpfs /run/lock \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  -p 5901:5901 -p 3389:3389 -p 22:22 \
  -e USER=<USERNAME> -e PASSWORD=<PASSWORD> -e VNCPASSWORD=<VNCPASSWORD> \
  -e ENABLE_X2GO=false -e ENABLE_VNC=true -e ENABLE_XRDP=true \
  mscrnt/ubuntu-desktop:headless
```

### 3. Accessing Your Container

- **Via VNC**: Connect to `localhost:5901` with a VNC client using the specified VNC password.
- **Via RDP**: Use any remote desktop client to connect to `localhost:3389` with the provided username and password.
- **Via SSH**: Connect to `localhost:22` using an SSH client and the given credentials.

### 4. Docker Compose

For convenience, you can also use Docker Compose. Create a `docker-compose.yaml` file with the following content, filling in the environment variables as needed:

```yaml
version: '3.8'
services:
  ubuntu-desktop:
    image: mscrnt/ubuntu-desktop:headless
    tmpfs:
      - /tmp
      - /run
      - /run/lock
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
    ports:
      - "5901:5901"
      - "3389:3389"
      - "22:22"
    environment:
      USER: <USERNAME>
      PASSWORD: <PASSWORD>
      VNCPASSWORD: <VNCPASSWORD>
      ENABLE_X2GO: "false"
      ENABLE_VNC: "true"
      ENABLE_XRDP: "true"
```

Replace `<USERNAME>`, `<PASSWORD>`, and `<VNCPASSWORD>` with your desired values. Adjust `ENABLE_X2GO`, `ENABLE_VNC`, and `ENABLE_XRDP` as per your requirements.

Run the container with Docker Compose:

```bash
docker-compose up -d
```

This setup provides a robust development environment with access to a wide range of tools and services, ideal for developers looking to isolate their workspace or experiment with different setups without affecting their host system.