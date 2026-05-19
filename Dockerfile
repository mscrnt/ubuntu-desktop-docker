# syntax=docker/dockerfile:1.7
ARG UBUNTU_VERSION=24.04
FROM ubuntu:${UBUNTU_VERSION}

ARG VARIANT=full
ARG INCLUDE_BROWSER=true
ARG INCLUDE_MEDIA=true
ARG INCLUDE_VSCODE=true
ARG INCLUDE_DEVTOOLS=true
ARG INCLUDE_NOMACHINE=false
ARG NOMACHINE_VERSION=9.5.7
ARG NOMACHINE_BUILD=2
# Space-separated extra Python interpreter versions to install via
# deadsnakes PPA (in addition to the distro default python3). Set to ""
# to skip. Honored only when INCLUDE_DEVTOOLS=true.
ARG PYTHON_VERSIONS="3.10 3.11 3.13"
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
        terminator \
        tilix \
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
    sed -i 's/^Storage=auto/Storage=persistent/' /etc/systemd/journald.conf && \
    # Disable NLA so Windows mstsc connects without TLS pre-auth negotiation
    # (xrdp's snakeoil cert isn't trusted, NLA handshake fails for most clients).
    sed -i 's/^security_layer=.*/security_layer=rdp/' /etc/xrdp/xrdp.ini

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
        # Extra Python interpreters via deadsnakes PPA. Ubuntu's `python3`
        # stays the default (3.12 on 24.04); these are co-installed as
        # python3.10, python3.11, python3.13, etc.
        if [ -n "${PYTHON_VERSIONS}" ]; then \
            install -d -m 0755 /etc/apt/keyrings && \
            curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xF23C5A6CF475977595C89F51BA6932366A755776" \
                | gpg --dearmor -o /etc/apt/keyrings/deadsnakes.gpg && \
            echo "deb [signed-by=/etc/apt/keyrings/deadsnakes.gpg] https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu noble main" \
                > /etc/apt/sources.list.d/deadsnakes.list && \
            apt-get update && \
            for v in ${PYTHON_VERSIONS}; do \
                apt-get install -y --no-install-recommends \
                    "python${v}" "python${v}-venv" "python${v}-dev"; \
            done; \
        fi && \
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
        install -d -m 0755 /etc/apt/keyrings && \
        # Mozilla Team PPA — provides a real .deb for firefox on Ubuntu 24.04
        # (the stock `firefox` package is a snap wrapper that doesn't run in
        # containers). Pin priority 1001 so it wins over the snap stub.
        curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x0AB215679C571D1C8325275B9BDB3D89CE49EC21" \
            | gpg --dearmor -o /etc/apt/keyrings/mozilla.gpg && \
        echo "deb [signed-by=/etc/apt/keyrings/mozilla.gpg] https://ppa.launchpadcontent.net/mozillateam/ppa/ubuntu noble main" \
            > /etc/apt/sources.list.d/mozillateam.list && \
        printf 'Package: firefox*\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001\n' \
            > /etc/apt/preferences.d/mozilla-firefox && \
        apt-get update && \
        apt-get install -y --no-install-recommends firefox && \
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
# Optional: NoMachine NX server (port 4000). Opt-in via INCLUDE_NOMACHINE=true.
# Personal use is permitted under NoMachine's free license; commercial users
# must obtain an Enterprise license — see https://www.nomachine.com/licensing.
# ---------------------------------------------------------------------------
RUN if [ "${INCLUDE_NOMACHINE}" = "true" ]; then \
        majmin="$(echo "${NOMACHINE_VERSION}" | cut -d. -f1-2)" && \
        case "${TARGETARCH}" in \
            amd64) nm_path=Linux; nm_arch=amd64 ;; \
            arm64) nm_path=Arm;   nm_arch=arm64 ;; \
            *) echo "NoMachine: unsupported TARGETARCH=${TARGETARCH}" >&2; exit 1 ;; \
        esac && \
        url="https://download.nomachine.com/download/${majmin}/${nm_path}/nomachine_${NOMACHINE_VERSION}_${NOMACHINE_BUILD}_${nm_arch}.deb" && \
        curl -fsSL -o /tmp/nomachine.deb "${url}" && \
        apt-get update && \
        apt-get install -y --no-install-recommends /tmp/nomachine.deb && \
        rm -f /tmp/nomachine.deb && \
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

RUN chmod +x /usr/local/bin/container-setup /usr/local/bin/healthcheck \
        /usr/local/sbin/container-init && \
    systemctl enable container-setup.service ssh.service xrdp.service && \
    systemctl set-default multi-user.target

EXPOSE 22 3389 4000 5901

HEALTHCHECK --interval=30s --timeout=5s --start-period=45s --retries=3 \
    CMD ["/usr/local/bin/healthcheck"]

ENTRYPOINT ["/usr/local/sbin/container-init"]
