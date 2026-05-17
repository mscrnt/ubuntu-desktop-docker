# Changelog

All notable changes to this project will be documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning is
[SemVer](https://semver.org/).

## [Unreleased]

### Changed
- **BREAKING:** Base image upgraded from Ubuntu 22.04 to Ubuntu 24.04.
- **BREAKING:** Renamed env var `USER` → `USERNAME` (avoids clobbering the
  POSIX `USER` variable inherited from the host shell).
- **BREAKING:** Removed the bash `entrypoint.sh` wrapper. The container now
  boots directly into `systemd` (`ENTRYPOINT ["/sbin/init"]`); first-boot
  configuration runs as the `container-setup.service` systemd oneshot. This
  makes `docker restart` work correctly.
- Single image replaces the prior `main` / `gpu` / `headless` branches.
  GPU usage is now a runtime concern (compose overlay or `--gpus all`),
  not a separate image.
- All `apt-key` usage replaced with `signed-by` keyrings under
  `/etc/apt/keyrings/`.
- Multi-arch images (`linux/amd64`, `linux/arm64`). On arm64, Chromium is
  installed instead of Google Chrome.

### Added
- Image variants via build args / tags: `:latest` (full) and `:slim`
  (no OBS, Chrome, or VS Code).
- `xrdp` is installed and enabled by default (was exposed but missing).
- `HEALTHCHECK` that verifies enabled service ports.
- Per-service toggles: `DISABLE_VNC`, `DISABLE_XRDP`, `DISABLE_SSH`.
- CI: hadolint, shellcheck, yamllint, actionlint, buildx, smoke test,
  Trivy scan.
- Release pipeline: multi-arch push to GHCR + Docker Hub, SBOM, provenance,
  cosign keyless signing.
- `docker-compose.gpu.yaml` overlay for NVIDIA GPU passthrough.

### Removed
- `snapd` (broken inside containers; refer to `apt` or `flatpak` instead).
- Privileged-mode requirement. No `/sys/fs/cgroup` mount needed on cgroup v2
  hosts.
- Legacy `gpu` and `headless` branches (archived as `legacy/gpu` and
  `legacy/headless` tags).
