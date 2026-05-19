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
| `:latest` | full | XFCE + VNC + xrdp + SSH + dev tools + **OBS, VLC, Firefox, VS Code** |
| `:slim` | small | XFCE + VNC + xrdp + SSH + dev tools (no media / browser / IDE) |

"Dev tools" = `build-essential`, `g++`, plus **Python 3.10, 3.11, 3.12, 3.13**
(distro default 3.12 + deadsnakes 3.10 / 3.11 / 3.13). Each is callable as
`python3.10`, `python3.11`, etc., with matching `-venv` and `-dev` packages.
Override at build time via `--build-arg PYTHON_VERSIONS="3.11 3.13"` or set
to empty to ship only the distro default.

NoMachine NX server (port 4000) is an opt-in build-time component on either
variant; enable with `INCLUDE_NOMACHINE=true` at build time and run the
container with `--cap-add=SYS_PTRACE`. See [Building locally](#building-locally).

Both are published for `linux/amd64` and `linux/arm64` to:

- `ghcr.io/mscrnt/ubuntu-desktop`
- `docker.io/mscrnt/ubuntu-desktop`

Images are signed with cosign (keyless OIDC) and ship with SBOM + provenance
attestations.

## Quick start

```sh
docker run -d --name desktop \
  --cgroupns=host \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  --tmpfs /run --tmpfs /run/lock --tmpfs /tmp \
  -p 2222:22 -p 13389:3389 -p 5901:5901 \
  -e USERNAME=user \
  -e PASSWORD=change-me \
  -e VNCPASSWORD=change-me \
  ghcr.io/mscrnt/ubuntu-desktop:latest
```

> systemd needs a writable cgroup tree. On cgroup v2 hosts the bind mount
> above (with `--cgroupns=host`) is sufficient — **no `--privileged` flag and
> no extra capabilities** are required.

> Host port `13389` is used for RDP because **Windows reserves `3389`** for
> its own Remote Desktop service even when it isn't actively serving
> connections. Mapping to `3389` on a Windows host causes `mstsc` to refuse
> the connection with error `0x708` / "console session in progress". Linux
> hosts can use `-p 3389:3389` freely.

Connect:

| Protocol | Host port | Notes |
|---|---|---|
| RDP | `13389` | Windows hosts: avoid `3389` (Windows RDP reserves it). Use mstsc, FreeRDP, NoMachine-as-RDP, etc. |
| VNC | `5901` | Any VNC client; uses `VNCPASSWORD`. Use display `:1` or explicit port `5901`. |
| SSH | `2222` | Maps to container `:22`; username/password from env. |
| NoMachine NX | `4000` | Only if image was built with `INCLUDE_NOMACHINE=true`. Container must be started with `--cap-add=SYS_PTRACE` (NoMachine's nxnode uses ptrace to spawn virtual sessions; default Docker AppArmor blocks it). |

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
| `DISABLE_NOMACHINE` | `0` | Set `1` to skip nxserver (only meaningful when image was built with NoMachine). |

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

With NoMachine NX server (port 4000) layered in:

```sh
make build NOMACHINE=true
# or:
docker buildx build --load --build-arg INCLUDE_NOMACHINE=true -t ubuntu-desktop:dev-nx .
```

NoMachine is opt-in because its license model differs from the rest of the
image. Personal use is permitted under the free license; commercial users
need an Enterprise license — see <https://www.nomachine.com/licensing>.

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

### Non-privileged on cgroup v2

The image does **not** require `--privileged`. Required runtime bits are:

- `--cgroupns=host`
- `-v /sys/fs/cgroup:/sys/fs/cgroup:rw` (writable cgroup tree)
- `--tmpfs /run --tmpfs /run/lock --tmpfs /tmp`
- `--cap-add=SYS_PTRACE` *only if NoMachine NX is enabled* (its `nxnode`
  uses ptrace; default Docker AppArmor blocks it — see
  [NoMachine KB DT07S00242](https://kb.nomachine.com/DT07S00242))

Why writable cgroup? With cgroup v2's unified hierarchy, systemd inside the
container needs to write to the cgroup it lives in to spawn child slices.
On cgroup v1 you could mount `:ro` — that's no longer enough on modern
hosts. The trade-off: a container with this mount can manipulate cgroups
visible to it; pair it with reasonable Docker user namespace settings if
that matters for your threat model.

## Branch model

- `main` — releases. Protected, PR-only.
- `dev` — integration; PRs target here.
- Legacy archived tags: `legacy/gpu`, `legacy/headless`.

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE).
