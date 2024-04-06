Understood! Here's the updated README file with instructions for both building from the Dockerfile and pulling the pre-built image `mscrnt/ubuntu-desktop:gpu` from Docker Hub. This version is ready to be included in your GitHub repository:

```markdown
# Developer Environment Docker

This Docker container offers a comprehensive development environment based on Ubuntu 22.04, featuring a range of tools and applications tailored for developers. It leverages the NVIDIA Container Toolkit for GPU support, enabling the use of GPU-accelerated applications without manual NVIDIA driver installations inside the container.

## Included Tools

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
- XFCE Desktop Environment

## Prerequisites

- Docker installed on your host machine.
- NVIDIA Container Toolkit installed on your host machine (for GPU support).

## Using the Pre-built Docker Image

For a quick setup, you can use the pre-built Docker image from Docker Hub.

### Running the Pre-built Container

1. Pull the Docker image from Docker Hub:

```bash
docker pull mscrnt/ubuntu-desktop:gpu
```

2. Run the Docker container with GPU support:

```bash
docker run --gpus all -it -p 5901:5901 -p 3389:3389 -p 22:22 -e USER=<USERNAME> -e PASSWORD=<PASSWORD> -e VNCPASSWORD=<VNCPASSWORD> mscrnt/ubuntu-desktop:gpu
```

Replace `<USERNAME>`, `<PASSWORD>`, and `<VNCPASSWORD>` with your desired credentials.

### Accessing the Container

- **VNC**: Connect to `localhost:5901` using a VNC client. Enter the VNCPASSWORD when prompted.
- **RDP**: Connect to `localhost:3389` using a Remote Desktop client. Login with the USERNAME and PASSWORD you set.
- **SSH**: Connect to `localhost:22` using an SSH client. Use the USERNAME and PASSWORD for authentication.

## Building the Docker Image from the Dockerfile

If you prefer to build the Docker image yourself or need to make modifications, follow these steps:

1. Clone or download this GitHub repository to your local machine.

2. Navigate to the directory containing the Dockerfile.

3. Build the Docker image using:

```bash
docker build -t your-image-name:tag .
```

Replace `your-image-name:tag` with your preferred image name and tag.

4. After building the image, you can run it using the same steps provided in the "Running the Pre-built Container" section, substituting `mscrnt/ubuntu-desktop:gpu` with `your-image-name:tag`.

## Docker Compose

Alternatively, you can use Docker Compose for easier management. Here's a sample `docker-compose.yaml`:

```yaml
version: "3.8"
services:
  ubuntu-desktop:
    container_name: ubuntu-desktop-container
    image: mscrnt/ubuntu-desktop:gpu
    environment:
      - USER=<USERNAME>
      - PASSWORD=<PASSWORD>
      - VNCPASSWORD=<VNCPASSWORD>
    ports:
      - "22:22"
      - "5901:5901"
      - "3389:3389"
```

Replace `<USERNAME>`, `<PASSWORD>`, and `<VNCPASSWORD>` with your specific values, then start the container with:

```bash
docker-compose up -d
```

Remember, if you built your own image, replace `mscrnt/ubuntu-desktop:gpu` with `your-image-name:tag` in the `docker-compose.yaml` file.
