#!/bin/bash
set -euo pipefail

exec /usr/local/lib/layerbrain/docker-compose-serial-up.sh /usr/libexec/docker/cli-plugins/docker-compose -- "$@"
