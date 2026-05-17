# ubuntu-desktop-docker

Ubuntu 24.04 XFCE desktop in a container, accessible over **VNC**, **xrdp**,
and **SSH**. Runs `systemd` as PID 1 so services start, stop, and restart
cleanly. Headless by default; opt in to NVIDIA GPU passthrough when you need
it.

[![build](https://github.com/mscrnt/ubuntu-desktop-docker/actions/workflows/build.yml/badge.svg)](https://github.com/mscrnt/ubuntu-desktop-docker/actions/workflows/build.yml)
[![release](https://github.com/mscrnt/ubuntu-desktop-docker/actions/workflows/release.yml/badge.svg)](https://github.com/mscrnt/ubuntu-desktop-docker/actions/workflows/release.yml)

## Image variants

| Tag | Size | Includes |
|---|---|---|
| `:latest` | full | XFCE + VNC + xrdp + SSH + dev tools + **OBS, VLC, Chrome/Chromium, VS Code** |
| `:slim` | small | XFCE + VNC + xrdp + SSH + dev tools (no media / browser / IDE) |

Both are published for `linux/amd64` and `linux/arm64` to:

- `ghcr.io/mscrnt/ubuntu-desktop`
- `docker.io/mscrnt/ubuntu-desktop`

Images are signed with cosign (keyless OIDC) and ship with SBOM + provenance
attestations.

## Quick start

```sh
docker run -d --name desktop \
  --cgroupns=host \
  --tmpfs /run --tmpfs /run/lock --tmpfs /tmp \
  -p 2222:22 -p 3389:3389 -p 5901:5901 \
  -e USERNAME=user \
  -e PASSWORD=change-me \
  -e VNCPASSWORD=change-me \
  ghcr.io/mscrnt/ubuntu-desktop:latest
```

Connect:

| Protocol | Host port | Notes |
|---|---|---|
| RDP | `3389` | Use any RDP client. Recommended for best UX. |
| VNC | `5901` | Any VNC client; uses `VNCPASSWORD`. |
| SSH | `2222` | Maps to container `:22`; username/password from env. |

## docker compose

```sh
cp .env.example .env
# edit .env, then:
docker compose up -d
```

With NVIDIA GPU passthrough (requires
[NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)):

```sh
docker compose -f docker-compose.yaml -f docker-compose.gpu.yaml up -d
```

## Configuration

Set at `docker run`/compose time:

| Variable | Default | Purpose |
|---|---|---|
| `USERNAME` | *(required)* | Login user; gets passwordless sudo. |
| `PASSWORD` | *(required)* | Account password for SSH / RDP / `sudo`. |
| `VNCPASSWORD` | *(required)* | VNC connection password. |
| `VNC_GEOMETRY` | `1920x1080` | VNC screen size. |
| `VNC_DEPTH` | `24` | VNC color depth. |
| `DISABLE_VNC` | `0` | Set `1` to skip VNC server. |
| `DISABLE_XRDP` | `0` | Set `1` to skip xrdp. |
| `DISABLE_SSH` | `0` | Set `1` to skip sshd. |

## Building locally

```sh
docker buildx build --load -t ubuntu-desktop:dev .

# slim variant
docker buildx build --load \
  --build-arg VARIANT=slim \
  --build-arg INCLUDE_BROWSER=false \
  --build-arg INCLUDE_MEDIA=false \
  --build-arg INCLUDE_VSCODE=false \
  -t ubuntu-desktop:dev-slim .
```

Smoke test:

```sh
IMAGE=ubuntu-desktop:dev ./tests/smoke.sh
```

## Why systemd inside the container?

XFCE, polkit, dbus services, xrdp's `sesman`, and several others expect a
working init system. The previous bash-`entrypoint.sh` approach started a
handful of daemons by hand and then `tail -f /dev/null`'d — which broke
`docker restart`, made VNC the only practical session backend, and meant
`systemctl` reported nonsense.

This image runs `/sbin/init` directly. First-boot configuration (user
creation, VNC password, sudoers drop-in) runs as the
[`container-setup.service`](rootfs/etc/systemd/system/container-setup.service)
oneshot, ordered before `ssh.service`, `xrdp.service`, and
`vncserver@.service`. The service is idempotent, so `docker restart desktop`
works.

**No `--privileged` required** on cgroup v2 hosts. The `--cgroupns=host` flag
plus tmpfs mounts for `/run`, `/run/lock`, and `/tmp` is sufficient.

## Branch model

- `main` — releases. Protected, PR-only.
- `dev` — integration; PRs target here.
- Legacy archived tags: `legacy/gpu`, `legacy/headless`.

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE).
