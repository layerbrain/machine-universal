#!/bin/bash
set -eo pipefail

compose_command=()
while [ "$#" -gt 0 ] && [ "$1" != "--" ]; do
    compose_command+=("$1")
    shift
done
if [ "$#" -eq 0 ]; then
    echo "docker-compose-serial-up requires a compose command before --" >&2
    exit 2
fi
shift

parallel_limit="${COMPOSE_PARALLEL_LIMIT:-1}"

args=("$@")
up_index=-1
for index in "${!args[@]}"; do
    if [ "${args[$index]}" = "up" ]; then
        up_index=$index
        break
    fi
done

if [ "$up_index" -lt 0 ] || [ "${COMPOSE_HARD_SERIAL_UP:-1}" = "0" ]; then
    exec "${compose_command[@]}" --parallel "$parallel_limit" "$@"
fi

global_args=("${args[@]:0:$up_index}")
up_args=("${args[@]:$((up_index + 1))}")
up_options=()
requested_services=()
detached=0
expect_option_value=0

for arg in "${up_args[@]}"; do
    if [ "$expect_option_value" -eq 1 ]; then
        up_options+=("$arg")
        expect_option_value=0
        continue
    fi
    case "$arg" in
        --)
            continue
            ;;
        -d|--detach)
            detached=1
            up_options+=("$arg")
            ;;
        --scale|--timeout|--wait-timeout|--exit-code-from|--attach|--no-attach)
            up_options+=("$arg")
            expect_option_value=1
            ;;
        -t)
            up_options+=("$arg")
            expect_option_value=1
            ;;
        --scale=*|--timeout=*|--wait-timeout=*|--exit-code-from=*|--attach=*|--no-attach=*)
            up_options+=("$arg")
            ;;
        -*)
            up_options+=("$arg")
            ;;
        *)
            requested_services+=("$arg")
            ;;
    esac
done

if [ "$detached" -ne 1 ]; then
    exec "${compose_command[@]}" --parallel "$parallel_limit" "$@"
fi

config_json=$("${compose_command[@]}" --parallel "$parallel_limit" "${global_args[@]}" config --format json)
service_order=$(
    python3 -c '
import json
import sys

requested = set(sys.argv[1:])
config = json.load(sys.stdin)
services = config.get("services") or {}

dependencies = {}
for name, service in services.items():
    raw = service.get("depends_on") or {}
    if isinstance(raw, dict):
        dependencies[name] = [dep for dep in raw if dep in services]
    elif isinstance(raw, list):
        dependencies[name] = [dep for dep in raw if dep in services]
    else:
        dependencies[name] = []

selected = set(services) if not requested else set()

def include_with_dependencies(name: str) -> None:
    if name not in services or name in selected:
        return
    for dependency in dependencies.get(name, []):
        include_with_dependencies(dependency)
    selected.add(name)

for service in requested:
    include_with_dependencies(service)

visited = set()
visiting = set()
ordered = []

def visit(name: str) -> None:
    if name in visited or name not in selected:
        return
    if name in visiting:
        return
    visiting.add(name)
    for dependency in dependencies.get(name, []):
        visit(dependency)
    visiting.remove(name)
    visited.add(name)
    ordered.append(name)

for service in services:
    visit(service)

for service in ordered:
    print(service)
' "${requested_services[@]}" <<< "$config_json"
)

while IFS= read -r service; do
    [ -n "$service" ] || continue
    "${compose_command[@]}" --parallel "$parallel_limit" "${global_args[@]}" up "${up_options[@]}" --no-deps "$service"
done <<< "$service_order"

exec "${compose_command[@]}" --parallel "$parallel_limit" "$@"
