# Developer Environment Docker

This Docker container provides a fully-equipped development environment built on Ubuntu 22.04 LTS. It includes a comprehensive suite of development tools and services, orchestrated under systemd as PID 1. This configuration adheres to the principle of least privilege, enhancing security while ensuring full functionality for services and applications that rely on systemd.

## Features

The container is pre-loaded with a wide array of tools and services, including:

- **OBS Studio, Google Chrome, Visual Studio Code**: Essential tools for development, screen recording, web testing, and source code editing.
- **Python 3.10 (with `venv` and `dev` packages), OpenSSH Server, TigerVNC Server**: For programming, secure access, and remote desktop capabilities.
- **VLC Media Player, Git, Curl, FFmpeg, Htop**: Utilities for media playback, version control, data transfer, media processing, and system monitoring.
- **XFCE Desktop Environment**: A lightweight desktop environment for a better GUI experience.
- **Snapd**: For snap package management, enhancing application installation and maintenance.

## Prerequisites

Ensure Docker is installed on your machine. For installation instructions, visit [Docker's official website](https://docs.docker.com/get-docker/).

For GPU support, the NVIDIA Container Toolkit must be installed. Follow the instructions at [NVIDIA Container Toolkit's documentation](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html) to set it up.

## Getting Started

### 1. Pull the Docker Image

Pull the image from Docker Hub:

```bash
docker pull mscrnt/ubuntu-desktop:latest
```

### 2. Run the Docker Container

To run the container with the necessary configurations:

```bash
docker run -d \
  --tmpfs /tmp \
  --tmpfs /run \
  --tmpfs /run/lock \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  -p 5901:5901 -p 3389:3389 -p 22:22 \
  -e USER=<USERNAME> -e PASSWORD=<PASSWORD> -e VNCPASSWORD=<VNCPASSWORD> \
  mscrnt/ubuntu-desktop:latest
```

For GPU support, add the `--gpus all` flag to your `docker run` command:

```bash
docker run -d \
  --gpus all \
  --tmpfs /tmp \
  --tmpfs /run \
  --tmpfs /run/lock \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  -p 5901:5901 -p 3389:3389 -p 22:22 \
  -e USER=<USERNAME> -e PASSWORD=<PASSWORD> -e VNCPASSWORD=<VNCPASSWORD> \
  mscrnt/ubuntu-desktop:latest
```

### 3. Accessing Your Container

- **Via VNC**: Connect to `localhost:5901` with a VNC client.
- **Via RDP**: Use any Remote Desktop client to connect to `localhost:3389`.
- **Via SSH**: Connect using an SSH client to `localhost:22`.

### 4. Docker Compose

For convenience, Docker Compose can be used. Create a `docker-compose.yaml` file with:

```yaml
version: '3.8'
services:
  ubuntu-desktop:
    image: mscrnt/ubuntu-desktop:latest
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
    deploy:
      resources:
        reservations:
          devices:
          - driver: nvidia
            capabilities: [gpu]
```

Replace placeholders with your desired configurations and run:

```bash
docker-compose up -d
```