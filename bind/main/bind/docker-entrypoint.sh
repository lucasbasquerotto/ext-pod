#!/bin/ash
set -e

if [ "$BIND_TYPE" = 'master' ]; then
    if [ ! -f "$ZONE_FINAL_FILE" ]; then
        dir="$(dirname "${ZONE_FINAL_FILE}")"
        mkdir -p "$dir"
        mv "$ZONE_INITIAL_FILE" "$ZONE_FINAL_FILE"
    fi
fi

exec "$@"

