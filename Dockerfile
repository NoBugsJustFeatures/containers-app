FROM php:8.2-cli

# Install Nginx
RUN apt-get update && apt-get install -y nginx

# Copy Nginx config
COPY docker/nginx.conf /etc/nginx/sites-available/default

# Your existing setup
RUN apt-get install -y \
    git unzip libpq-dev libzip-dev libonig-dev libxml2-dev \
    && docker-php-ext-install pdo pdo_mysql mbstring zip exif pcntl bcmath \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

WORKDIR /var/www/html
COPY . .

# Start both services (Nginx + Laravel)
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]

