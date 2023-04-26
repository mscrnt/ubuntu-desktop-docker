FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

# Update package index and install required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    wget \
    gnupg \
    software-properties-common

# Add required repositories
RUN add-apt-repository ppa:graphics-drivers/ppa && \
    add-apt-repository ppa:obsproject/obs-studio && \
    add-apt-repository ppa:mozillateam/ppa

# Install CUDA, cuDNN, NVIDIA driver, and other dependencies
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin && \
    mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600 && \
    apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/3bf863cc.pub && \
    add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/ /" && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    g++ \
    freeglut3-dev \
    build-essential \
    libx11-dev \
    libxmu-dev \
    libxi-dev \
    libglu1-mesa \
    libglu1-mesa-dev \
    ca-certificates \
    libnvidia-common-530 \
    libnvidia-gl-530 \
    nvidia-driver-530 \
    cuda-11-7=11.7.0-1

# Copy cuDNN files to the Docker image
COPY cudnn-linux-x86_64-8.5.0.96_cuda11-archive.tar.xz /tmp/cudnn-linux-x86_64-8.5.0.96_cuda11-archive.tar.xz

# Install cuDNN v11.7
RUN tar -xvf /tmp/cudnn-linux-x86_64-8.5.0.96_cuda11-archive.tar.xz -C /tmp && \
    cp -P /tmp/cudnn-linux-x86_64-8.5.0.96_cuda11-archive/include/cudnn.h /usr/local/cuda-11.7/include && \
    cp -P /tmp/cudnn-linux-x86_64-8.5.0.96_cuda11-archive/lib/libcudnn* /usr/local/cuda-11.7/lib64/ && \
    chmod a+r /usr/local/cuda-11.7/lib64/libcudnn* && \
    rm -rf /tmp/cudnn-linux-x86_64-8.5.0.96_cuda11-archive.tar.xz /tmp/cudnn-linux-x86_64-8.5.0.96_cuda11-archive

# Set up environment variables for CUDA
ENV PATH=/usr/local/cuda-11.7/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/cuda-11.7/lib64:$LD_LIBRARY_PATH

# Add Microsoft repository for Visual Studio Code
RUN wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | apt-key add - && \
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list

# Update package index
RUN apt-get update

# Set package priority and unattended upgrades for Firefox
RUN printf "Package: *\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001\n" | tee /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:${distro_codename}";' | tee /etc/apt/apt.conf.d/51unattended-upgrades-firefox

# Install required packages
RUN apt-get install -y \
        obs-studio \
        code \
        firefox \
        python3.10 \
        python3.10-venv \
        python3.10-dev \
        openssh-server \
        tigervnc-standalone-server \
        tigervnc-xorg-extension \
        tigervnc-viewer \
        xorg \
        xfce4 \
        dbus-x11 \
        xrdp \
        sudo \
        git \
        curl \
        ffmpeg \
        htop \
        vlc \
        x11-xserver-utils \
        xfce4-terminal \
        dbus && \
    apt-get clean

# Install CUDA, cuDNN, and other required dependencies
RUN apt-get install -y --no-install-recommends \
        cuda-libraries-11-4 \
        libcudnn8 \
        libcudnn8-dev \
        libnccl2 \
        libnccl-dev \
        libnvrtc10 && \
    apt-get clean

# Configure sshd
RUN sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config && \
    mkdir /var/run/sshd

# Enable persistent logging
RUN sed -i 's/Storage=auto/Storage=persistent/' /etc/systemd/journald.conf

# Set environment variables
ENV USER=""
ENV PASSWORD=""
ENV VNCPASSWORD=""

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22 5901 3389

ENTRYPOINT ["/entrypoint.sh"]
