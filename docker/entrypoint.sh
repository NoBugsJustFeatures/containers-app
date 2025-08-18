#!/bin/sh
# Add to container's /etc/hosts
echo "172.20.0.1 mylaravelapp.local" >> /etc/hosts

# Start original Nginx entrypoint
exec /docker-entrypoint.sh "$@"
