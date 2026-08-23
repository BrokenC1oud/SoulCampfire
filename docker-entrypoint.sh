#!/bin/sh
set -eu

# A bind mount replaces the image directory and may be owned by root.
mkdir -p /app/data
chown soulcampfire:soulcampfire /app/data

exec gosu soulcampfire:soulcampfire /app/SoulCampfire "$@"
