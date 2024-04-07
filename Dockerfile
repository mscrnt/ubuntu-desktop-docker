FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

ENV container=docker
STOPSIGNAL SIGRTMIN+3

# Update package index and install required base packages
RUN apt-get update && \
    apt-get install -y systemd systemd-sysv ca-certificates wget gnupg software-properties-common g++ freeglut3-dev build-essential libx11-dev libxmu-dev libxi-dev libglu1-mesa libglu1-mesa-dev python3.10 python3.10-venv python3.10-dev openssh-server tigervnc-standalone-server tigervnc-xorg-extension tigervnc-viewer xorg xfce4 dbus-x11 sudo git curl nano tmux ffmpeg htop vlc x11-xserver-utils xfce4-terminal dbus snapd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done) && \
    rm -f /lib/systemd/system/multi-user.target.wants/* && \
    rm -f /etc/systemd/system/*.wants/* && \
    rm -f /lib/systemd/system/local-fs.target.wants/* && \
    rm -f /lib/systemd/system/sockets.target.wants/*udev* && \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl* && \
    rm -f /lib/systemd/system/basic.target.wants/* && \
    rm -f /lib/systemd/system/anaconda.target.wants/* && \
    find /etc/systemd/system /lib/systemd/system -path '*.wants/*' -exec rm \{} \; && \
    echo 'tmpfs /run tmpfs mode=755,nosuid,nodev 0 0' > /etc/fstab && \
    echo 'tmpfs /tmp tmpfs mode=1777,nosuid,nodev 0 0' >> /etc/fstab

# Generate machine-id
RUN systemd-machine-id-setup

# Add required repositories and keys for OBS Studio, VS Code, Google Chrome
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys BC7345F522079769F5BBE987EFC71127F425E228 A7D8D681B1C07FE41499323D7CDE3A860A53F9FD && \
    wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | apt-key add - && \
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    add-apt-repository ppa:obsproject/obs-studio && \
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list && \
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list

# Update package index again and install OBS Studio, VS Code, Google Chrome
RUN apt-get update && \
    apt-get install -y obs-studio code google-chrome-stable && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Configure SSH and logging
RUN sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config && \
    mkdir /var/run/sshd && \
    sed -i 's/Storage=auto/Storage=persistent/' /etc/systemd/journald.conf

# Install snapd
RUN apt-get update && \
    apt-get install -y snapd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV USER="" \
    PASSWORD="" \
    VNCPASSWORD="" 

# Copy entrypoint script and make it executable
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose necessary ports
EXPOSE 22 5901 3389

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
