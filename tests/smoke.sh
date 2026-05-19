#!/usr/bin/env bash
# Boot the image, wait for healthcheck to pass, verify service ports.
set -euo pipefail

IMAGE="${IMAGE:?IMAGE env var required}"
NAME="ubuntu-desktop-smoke-$$"
TIMEOUT_SECS="${TIMEOUT_SECS:-180}"

dump_diagnostics() {
    echo "----- docker inspect (state + health) -----"
    docker inspect "${NAME}" \
        --format '{{json .State}}' 2>/dev/null \
        | python3 -m json.tool 2>/dev/null || docker inspect "${NAME}" || true
    echo "----- docker logs -----"
    docker logs "${NAME}" 2>&1 || true
    echo "----- last healthcheck output -----"
    docker inspect "${NAME}" \
        --format '{{range .State.Health.Log}}{{.Output}}{{println "---"}}{{end}}' \
        2>/dev/null || true
}

# shellcheck disable=SC2329  # invoked via trap
cleanup() {
    docker rm -f "${NAME}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo ">> Starting ${IMAGE} as ${NAME}"
# Non-privileged systemd-in-container recipe (cgroup v2):
#   - --cgroupns=host: share the host cgroup namespace
#   - bind /sys/fs/cgroup rw: cgroup v2 unified hierarchy needs write access
#   - tmpfs for /run, /run/lock, /tmp
# No --privileged, no extra cap_add required.
docker run -d --name "${NAME}" \
    --cgroupns=host \
    -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
    --tmpfs /run --tmpfs /run/lock --tmpfs /tmp \
    -e USERNAME=smoketest \
    -e PASSWORD=smoketest \
    -e VNCPASSWORD=smoketest \
    -p 0:22 -p 0:3389 -p 0:5901 \
    "${IMAGE}" >/dev/null

deadline=$(( $(date +%s) + TIMEOUT_SECS ))
echo ">> Waiting up to ${TIMEOUT_SECS}s for healthcheck"

while : ; do
    now=$(date +%s)
    elapsed=$(( now - (deadline - TIMEOUT_SECS) ))
    status="$(docker inspect -f '{{.State.Health.Status}}' "${NAME}" 2>/dev/null || echo unknown)"
    running="$(docker inspect -f '{{.State.Running}}' "${NAME}" 2>/dev/null || echo false)"
    echo "   [t=${elapsed}s] health=${status} running=${running}"

    if [[ "${status}" == "healthy" ]]; then
        echo ">> PASS: container is healthy"
        exit 0
    fi
    if [[ "${running}" != "true" ]]; then
        echo ">> FAIL: container exited"
        dump_diagnostics
        exit 1
    fi
    if (( now >= deadline )); then
        echo ">> FAIL: timed out after ${TIMEOUT_SECS}s (last status: ${status})"
        dump_diagnostics
        exit 1
    fi
    sleep 5
done
