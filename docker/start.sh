#!/bin/bash

# Start PHP-FPM in background
service php8.2-fpm start

# Run database migrations (optional)
php artisan migrate --force

# Optimize Laravel
php artisan optimize:clear
php artisan optimize
php artisan view:cache

# Start Nginx in foreground
exec nginx -g "daemon off;"
