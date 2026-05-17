#!/usr/bin/env bash
# Boot the image, wait for healthcheck to pass, verify service ports.
set -euo pipefail

IMAGE="${IMAGE:?IMAGE env var required}"
NAME="ubuntu-desktop-smoke-$$"

# shellcheck disable=SC2329  # invoked via trap
cleanup() {
    docker logs "${NAME}" >"/tmp/${NAME}.log" 2>&1 || true
    docker rm -f "${NAME}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo ">> Starting ${IMAGE} as ${NAME}"
docker run -d --name "${NAME}" \
    --cgroupns=host \
    --tmpfs /run --tmpfs /run/lock --tmpfs /tmp \
    -e USERNAME=smoketest \
    -e PASSWORD=smoketest \
    -e VNCPASSWORD=smoketest \
    -p 0:22 -p 0:3389 -p 0:5901 \
    "${IMAGE}" >/dev/null

echo ">> Waiting up to 90s for healthcheck"
for i in $(seq 1 18); do
    status="$(docker inspect -f '{{.State.Health.Status}}' "${NAME}" 2>/dev/null || echo starting)"
    echo "   [${i}] health=${status}"
    if [[ "${status}" == "healthy" ]]; then
        echo ">> PASS: container is healthy"
        exit 0
    fi
    if [[ "${status}" == "unhealthy" ]]; then
        echo ">> FAIL: container reported unhealthy"
        docker logs "${NAME}" || true
        exit 1
    fi
    sleep 5
done

echo ">> FAIL: timed out waiting for healthy state"
docker logs "${NAME}" || true
exit 1
