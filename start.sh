#!/bin/bash
set -Eeuo pipefail

DOCKER_SUPERVISOR_PID=""
SSHD_SUPERVISOR_PID=""
COMMAND_PID=""

echo "=================================="
echo "Welcome to Layerbrain!!!"
echo "=================================="

/opt/layerbrain/setup.sh

ROOT_HOME="$(getent passwd root 2>/dev/null | cut -d: -f6)"
if [ -z "$ROOT_HOME" ]; then
    ROOT_HOME="$(eval echo ~root)"
fi
ROOT_SSH_DIR="${ROOT_HOME}/.ssh"

stop_pid() {
    local pid="$1"
    [ -n "$pid" ] || return 0
    kill "$pid" >/dev/null 2>&1 || return 0
}

shutdown() {
    trap - TERM INT EXIT
    stop_pid "$COMMAND_PID"
    stop_pid "$SSHD_SUPERVISOR_PID"
    stop_pid "$DOCKER_SUPERVISOR_PID"
    wait >/dev/null 2>&1 || true
}

trap shutdown TERM INT EXIT

configure_ssh() {
    [ -n "${SSH_PUBLIC_KEY:-}" ] || return 0

    mkdir -p "$ROOT_SSH_DIR" /var/run/sshd
    chmod 700 "$ROOT_SSH_DIR"
    echo "$SSH_PUBLIC_KEY" > "${ROOT_SSH_DIR}/authorized_keys"
    chmod 600 "${ROOT_SSH_DIR}/authorized_keys"
    echo "SSH public key configured."

    cat > /usr/local/bin/ssh-wrapper.sh << 'WRAPPER_EOF'
#!/bin/bash
source /opt/layerbrain/init-env.sh 2>/dev/null || true
if [ -z "$SSH_ORIGINAL_COMMAND" ]; then
    exec "${SHELL:-/bin/bash}" -l
else
    exec "${SHELL:-/bin/bash}" -c "$SSH_ORIGINAL_COMMAND"
fi
WRAPPER_EOF
    chmod +x /usr/local/bin/ssh-wrapper.sh

    if ! grep -q '^ForceCommand /usr/local/bin/ssh-wrapper.sh$' /etc/ssh/sshd_config; then
        echo 'ForceCommand /usr/local/bin/ssh-wrapper.sh' >> /etc/ssh/sshd_config
    fi
}

supervise_sshd() {
    local sshd_pid=""
    trap 'stop_pid "$sshd_pid"; exit 0' TERM INT EXIT

    while true; do
        rm -f /var/run/sshd.pid /run/sshd.pid
        /usr/sbin/sshd -D -e &
        sshd_pid="$!"
        status=0
        wait "$sshd_pid" || status=$?
        sshd_pid=""
        echo "sshd exited with status ${status}; restarting in 2s." >&2
        sleep 2
    done
}

docker_pid_is_stale() {
    local pid_file="$1"
    [ -f "$pid_file" ] || return 1

    local pid
    pid="$(cat "$pid_file" 2>/dev/null || true)"
    if [ -z "$pid" ] || ! kill -0 "$pid" >/dev/null 2>&1; then
        return 0
    fi

    local state
    state="$(ps -o stat= -p "$pid" 2>/dev/null | tr -d '[:space:]' || true)"
    [ -z "$state" ] || [[ "$state" == Z* ]]
}

cleanup_stale_docker_state() {
    local pid_file
    for pid_file in \
        /var/run/docker.pid \
        /run/docker.pid \
        /var/run/docker/containerd/containerd.pid \
        /run/docker/containerd/containerd.pid
    do
        if docker_pid_is_stale "$pid_file"; then
            rm -f "$pid_file"
        fi
    done

    if ! pgrep -x dockerd >/dev/null 2>&1; then
        rm -f /var/run/docker.sock /run/docker.sock
    fi
}

supervise_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        echo "Warning: Docker CLI is not installed in this image." >&2
        return 0
    fi
    if ! command -v dockerd >/dev/null 2>&1; then
        echo "Warning: Docker daemon is not installed in this image." >&2
        return 0
    fi

    sysctl -p /etc/sysctl.conf >/dev/null 2>&1 || true
    mkdir -p /var/lib/docker /var/log /var/run/docker

    local backoff=1
    local docker_pid=""
    trap 'stop_pid "$docker_pid"; exit 0' TERM INT EXIT

    while true; do
        cleanup_stale_docker_state
        echo "Starting Docker daemon..."
        dockerd >> /var/log/dockerd.log 2>&1 &
        docker_pid=$!

        status=0
        wait "$docker_pid" || status=$?
        docker_pid=""
        echo "dockerd exited with status ${status}; restarting in ${backoff}s." >&2
        sleep "$backoff"
        if [ "$backoff" -lt 30 ]; then
            backoff=$((backoff * 2))
        fi
    done
}

wait_for_docker() {
    command -v docker >/dev/null 2>&1 || return 0
    command -v dockerd >/dev/null 2>&1 || return 0

    echo -n "Waiting for Docker to be ready"
    for _ in {1..60}; do
        if docker info >/dev/null 2>&1; then
            echo ""
            echo "Docker is ready."
            return 0
        fi
        echo -n "."
        sleep 1
    done
    echo ""
    echo "Warning: Docker did not become ready within 60 seconds. Check /var/log/dockerd.log." >&2
}

start_background_services() {
    echo ""
    echo "=== Starting Docker ==="
    if command -v docker >/dev/null 2>&1 && command -v dockerd >/dev/null 2>&1; then
        supervise_docker &
        DOCKER_SUPERVISOR_PID="$!"
        wait_for_docker
    else
        supervise_docker
    fi
    echo "=================================="

    if [ -n "${SSH_PUBLIC_KEY:-}" ]; then
        configure_ssh
        supervise_sshd &
        SSHD_SUPERVISOR_PID="$!"
        echo "SSH server started on port 22."
    fi
}

start_background_services

if [ "$#" -gt 0 ]; then
    "$@" &
    COMMAND_PID="$!"
    status=0
    wait "$COMMAND_PID" || status=$?
    exit "$status"
fi

if [ -n "${SSH_PUBLIC_KEY:-}" ]; then
    echo "Server runtime is active."
    while true; do
        if [ -n "$DOCKER_SUPERVISOR_PID" ] && ! kill -0 "$DOCKER_SUPERVISOR_PID" >/dev/null 2>&1; then
            echo "Docker supervisor exited unexpectedly." >&2
            exit 1
        fi
        if ! kill -0 "$SSHD_SUPERVISOR_PID" >/dev/null 2>&1; then
            echo "SSH supervisor exited unexpectedly." >&2
            exit 1
        fi
        sleep 5
    done
fi

echo "Environment ready. Dropping you into a bash shell."
bash --login &
COMMAND_PID="$!"
status=0
wait "$COMMAND_PID" || status=$?
exit "$status"
