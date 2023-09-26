# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04
ARG DEBIAN_FRONTEND=noninteractive

# Install systemd and set it as the init system
ENV container docker
STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]

# Update package index and install required packages
RUN apt-get update && \
    apt-get install -y \
        systemd systemd-sysv ca-certificates wget gnupg software-properties-common && \
    rm -rf /var/lib/apt/lists/*  # Cleanup to reduce image size

# Add required repositories and keys
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys BC7345F522079769F5BBE987EFC71127F425E228 A7D8D681B1C07FE41499323D7CDE3A860A53F9FD && \
    wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | apt-key add - && \
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb [arch=amd64] https://ppa.launchpadcontent.net/obsproject/obs-studio/ubuntu jammy main" >> /etc/apt/sources.list && \
    echo "deb [arch=amd64] https://ppa.launchpadcontent.net/x2go/stable/ubuntu jammy main" >> /etc/apt/sources.list && \
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list && \
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list

# Update package index again and install all remaining packages
RUN apt-get update && \
    apt-get install -y \
        obs-studio code google-chrome-stable python3.10 python3.10-venv python3.10-dev openssh-server \
        tigervnc-standalone-server tigervnc-xorg-extension tigervnc-viewer xorg xfce4 dbus-x11 \
        xrdp x2goserver x2goserver-xsession sudo git curl nano tmux ffmpeg htop vlc \
        x11-xserver-utils xfce4-terminal dbus && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*  # Cleanup to reduce image size

# Configure SSH and logging
RUN sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config && \
    mkdir /var/run/sshd && \
    sed -i 's/Storage=auto/Storage=persistent/' /etc/systemd/journald.conf

# Set environment variables
ENV USER=""
ENV PASSWORD=""
ENV VNCPASSWORD=""
ENV ENABLE_X2GO="false"
ENV ENABLE_VNC="false"
ENV ENABLE_XRDP="false"

# Copy entrypoint script and make it executable
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose necessary ports
EXPOSE 22 5901 3389

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
