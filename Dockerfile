# syntax=docker/dockerfile:1.7
ARG UBUNTU_VERSION=24.04
FROM ubuntu:${UBUNTU_VERSION}

ARG VARIANT=full
ARG INCLUDE_BROWSER=true
ARG INCLUDE_MEDIA=true
ARG INCLUDE_VSCODE=true
ARG INCLUDE_DEVTOOLS=true
ARG TARGETARCH

LABEL org.opencontainers.image.title="ubuntu-desktop" \
      org.opencontainers.image.description="Ubuntu 24.04 XFCE desktop with VNC, xrdp, and SSH, running under systemd." \
      org.opencontainers.image.source="https://github.com/mscrnt/ubuntu-desktop-docker" \
      org.opencontainers.image.licenses="MIT" \
      io.ubuntu-desktop.variant="${VARIANT}"

ARG DEBIAN_FRONTEND=noninteractive
ENV container=docker \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8
STOPSIGNAL SIGRTMIN+3

# Fail-fast pipes: required so `curl … | gpg --dearmor` propagates curl errors.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# ---------------------------------------------------------------------------
# Base system: systemd as PID 1.
# Strip units that don't make sense inside a container (udev, getty,
# console, fs mounts) so boot is fast and quiet, and `docker restart` works.
# ---------------------------------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dbus \
        gnupg \
        iproute2 \
        locales \
        sudo \
        systemd \
        systemd-sysv \
        tzdata \
        wget && \
    rm -rf /var/lib/apt/lists/* && \
    find /etc/systemd/system /lib/systemd/system \
        -path '*.wants/*' \
        -not -name '*systemd-tmpfiles-setup*' \
        -not -name '*journald*' \
        -not -name '*tmp.mount*' \
        -delete && \
    rm -f /lib/systemd/system/systemd-update-utmp* \
          /lib/systemd/system/systemd-firstboot* \
          /lib/systemd/system/systemd-remount-fs* \
          /lib/systemd/system/system-getty.slice && \
    systemd-machine-id-setup

# ---------------------------------------------------------------------------
# Desktop, remote access, and core utilities. Always installed.
# ---------------------------------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        dbus-x11 \
        fonts-dejavu-core \
        fonts-liberation \
        git \
        htop \
        nano \
        openssh-server \
        tigervnc-standalone-server \
        tigervnc-tools \
        tigervnc-xorg-extension \
        tmux \
        vim-tiny \
        x11-xserver-utils \
        xauth \
        xfce4 \
        xfce4-goodies \
        xfce4-terminal \
        xorg \
        xorgxrdp \
        xrdp && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/run/sshd && \
    sed -i \
        -e 's/^#\?PermitRootLogin.*/PermitRootLogin no/' \
        -e 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' \
        /etc/ssh/sshd_config && \
    adduser xrdp ssl-cert && \
    sed -i 's/^Storage=auto/Storage=persistent/' /etc/systemd/journald.conf

# ---------------------------------------------------------------------------
# Optional: developer toolchain (Python, build-essential).
# ---------------------------------------------------------------------------
RUN if [ "${INCLUDE_DEVTOOLS}" = "true" ]; then \
        apt-get update && \
        apt-get install -y --no-install-recommends \
            build-essential \
            g++ \
            python3 \
            python3-dev \
            python3-venv \
            python3-pip && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*; \
    fi

# ---------------------------------------------------------------------------
# Optional: media tools (OBS Studio, VLC, ffmpeg).
# ---------------------------------------------------------------------------
RUN if [ "${INCLUDE_MEDIA}" = "true" ]; then \
        apt-get update && \
        apt-get install -y --no-install-recommends \
            ffmpeg \
            ffmpegthumbnailer \
            obs-studio \
            vlc && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*; \
    fi

# ---------------------------------------------------------------------------
# Optional: web browser. Chrome on amd64, Chromium on arm64 (Google doesn't
# publish Chrome for arm64).
# ---------------------------------------------------------------------------
RUN if [ "${INCLUDE_BROWSER}" = "true" ]; then \
        if [ "${TARGETARCH}" = "amd64" ]; then \
            install -d -m 0755 /etc/apt/keyrings && \
            curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
                | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg && \
            echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
                > /etc/apt/sources.list.d/google-chrome.list && \
            apt-get update && \
            apt-get install -y --no-install-recommends google-chrome-stable; \
        else \
            apt-get update && \
            apt-get install -y --no-install-recommends chromium-browser || \
            apt-get install -y --no-install-recommends chromium; \
        fi && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*; \
    fi

# ---------------------------------------------------------------------------
# Optional: Visual Studio Code (Microsoft publishes amd64 + arm64).
# ---------------------------------------------------------------------------
RUN if [ "${INCLUDE_VSCODE}" = "true" ]; then \
        install -d -m 0755 /etc/apt/keyrings && \
        curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
            | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg && \
        echo "deb [arch=amd64,arm64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" \
            > /etc/apt/sources.list.d/vscode.list && \
        apt-get update && \
        apt-get install -y --no-install-recommends code && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*; \
    fi

# ---------------------------------------------------------------------------
# Default runtime configuration. Override at `docker run` time.
# ---------------------------------------------------------------------------
ENV USERNAME="" \
    PASSWORD="" \
    VNCPASSWORD="" \
    VNC_GEOMETRY="1920x1080" \
    VNC_DEPTH="24" \
    DISABLE_VNC="0" \
    DISABLE_XRDP="0" \
    DISABLE_SSH="0"

# Image overlay: systemd units + helper scripts.
COPY rootfs/ /

RUN chmod +x /usr/local/bin/container-setup /usr/local/bin/healthcheck && \
    systemctl enable container-setup.service ssh.service xrdp.service && \
    systemctl set-default multi-user.target

EXPOSE 22 3389 5901

HEALTHCHECK --interval=30s --timeout=5s --start-period=45s --retries=3 \
    CMD ["/usr/local/bin/healthcheck"]

ENTRYPOINT ["/sbin/init"]
