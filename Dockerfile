FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

# Update package index and install required base packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    wget \
    gnupg \
    software-properties-common \
    g++ \
    freeglut3-dev \
    build-essential \
    libx11-dev \
    libxmu-dev \
    libxi-dev \
    libglu1-mesa \
    libglu1-mesa-dev \
    ca-certificates \
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
    nano \
    tmux \
    ffmpeg \
    htop \
    vlc \
    x11-xserver-utils \
    xfce4-terminal \
    dbus && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add Microsoft repository for Visual Studio Code
RUN wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | apt-key add - && \
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list && \
    apt-get update && \
    apt-get install -y code && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add required repositories for OBS Studio and Firefox
RUN add-apt-repository ppa:obsproject/obs-studio && \
    add-apt-repository ppa:mozillateam/ppa && \
    apt-get update && \
    apt-get install -y obs-studio firefox && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Configure SSHD
RUN sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config && \
    mkdir /var/run/sshd

# Enable persistent logging
RUN sed -i 's/Storage=auto/Storage=persistent/' /etc/systemd/journald.conf

# Set environment variables (customize these as needed)
ENV USER=""
ENV PASSWORD=""
ENV VNCPASSWORD=""

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22 5901 3389

ENTRYPOINT ["/entrypoint.sh"]
