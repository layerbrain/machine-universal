#!/bin/bash
set -euo pipefail

if [ "${1:-}" = "compose" ]; then
    shift
    exec /usr/local/lib/layerbrain/docker-compose-serial-up.sh /usr/bin/docker compose -- "$@"
fi

exec /usr/bin/docker "$@"
