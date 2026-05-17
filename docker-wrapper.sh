#!/bin/bash
set -euo pipefail

if [ "${1:-}" = "compose" ]; then
    export COMPOSE_PARALLEL_LIMIT="${COMPOSE_PARALLEL_LIMIT:-1}"
fi

exec /usr/bin/docker "$@"
