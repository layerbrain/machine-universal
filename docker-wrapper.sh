#!/bin/bash
set -euo pipefail

if [ "${1:-}" = "compose" ]; then
    parallel_limit="${COMPOSE_PARALLEL_LIMIT:-1}"
    shift
    exec /usr/bin/docker compose --parallel "$parallel_limit" "$@"
fi

exec /usr/bin/docker "$@"
