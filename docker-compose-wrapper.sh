#!/bin/bash
set -euo pipefail

export COMPOSE_PARALLEL_LIMIT="${COMPOSE_PARALLEL_LIMIT:-1}"
exec /usr/libexec/docker/cli-plugins/docker-compose "$@"
