# Security policy

## Supported versions

Only the `:latest` tag and the most recent semver release receive security
updates. Older tags are immutable.

## Reporting a vulnerability

Report security issues privately via GitHub Security Advisories:
<https://github.com/mscrnt/ubuntu-desktop-docker/security/advisories/new>.

Please do not open public issues for security reports.

## Hardening notes for operators

- The image runs `systemd` as PID 1. It does **not** require `--privileged`
  on cgroup v2 hosts; use `--cgroupns=host` plus the documented tmpfs mounts.
- SSH is enabled by default with password authentication. For production,
  bake an authorized public key into the user's `~/.ssh/authorized_keys` and
  set `PasswordAuthentication no` in `/etc/ssh/sshd_config`.
- The `USERNAME` account has passwordless `sudo`. Treat the container as a
  workstation, not a hardened server.
- Do not expose ports 22 / 3389 / 5901 to the public internet without a
  VPN or reverse proxy fronting them.
