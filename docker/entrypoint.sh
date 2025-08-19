#!/bin/bash
# Add host entry to container's /etc/hosts
echo "127.0.0.1 mylaravelapp.local" >> /etc/hosts

# Start main command
exec "$@"