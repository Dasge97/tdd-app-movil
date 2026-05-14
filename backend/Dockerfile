FROM php:8.4-fpm-alpine

RUN apk add --no-cache \
    nginx \
    supervisor \
    icu-dev \
    libzip-dev \
    oniguruma-dev \
    && docker-php-ext-install \
    pdo_mysql \
    intl \
    zip \
    bcmath \
    opcache

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY composer.json composer.lock symfony.lock ./
RUN composer install --no-dev --optimize-autoloader --no-interaction

COPY . .

RUN chown -R www-data:www-data var/ public/

# nginx config
COPY docker/nginx.conf /etc/nginx/nginx.conf

# supervisor config
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 3000

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
