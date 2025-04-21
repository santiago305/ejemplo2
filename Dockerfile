# Fase 1: Build del frontend
FROM node:20 AS frontend

WORKDIR /app

COPY ./frontend/package*.json ./
RUN npm install

COPY ./frontend ./
RUN npm run build

# Fase 2: Backend Laravel
FROM php:8.2-fpm AS backend

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    git \
    unzip \
    curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd zip pdo pdo_mysql

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

# Copiar todo el proyecto Laravel
COPY . .

# Instalar dependencias de PHP
RUN composer install --no-interaction --optimize-autoloader

# Si usas Vite y ya configuraste el build en public/build, este paso NO es necesario:
# COPY --from=frontend /app/dist /var/www/public/build

# Comandos artisan (excepto migrate)
# RUN php artisan key:generate
RUN php artisan optimize
RUN php artisan config:cache
RUN php artisan route:cache
RUN php artisan view:cache
RUN php artisan storage:link

# Permisos
RUN chown -R www-data:www-data /var/www
RUN chmod -R 775 storage bootstrap/cache

EXPOSE 9000
CMD ["php-fpm"]
