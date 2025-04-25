FROM php:8.4-fpm-bookworm

ENV TZ=UTC
ENV COMPOSER_VERSION=2.8.8

RUN apt update && \
    apt upgrade -y && \
    apt install -y --no-install-recommends \
      apache2 \
      libffi8 \
      libffi-dev \
      libicu72 \
      libicu-dev \
      libjpeg-dev \
      libjpeg62-turbo-dev \
      libjpeg62-turbo \
      libmagickwand-6.q16-6 \
      libmagickwand-dev \
      libmagickcore-6.q16-6 \
      libmagickcore-dev \
      libonig5 \
      libonig-dev \
      libpng16-16 \
      libpng-dev \
      librabbitmq4 \
      librabbitmq-dev \
      libtidy5deb1 \
      libtidy-dev \
      libxml2 \
      libxml2-dev \
      libxslt1.1 \
      libxslt-dev \
      libzip4 \
      libzip-dev \
      libcurl4 \
      libcurl4-openssl-dev \
      supervisor \
      wget && \
    rm -rf /var/lib/apt/lists/*

### PHP
RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install -j$(nproc) \
      bcmath \
      calendar \
      exif \
      ffi \
      ftp \
      gd \
      gettext \
      intl \
      mysqli \
      opcache \
      pcntl \
      pdo_mysql \
      shmop \
      soap \
      sysvmsg \
      sysvsem \
      sysvshm \
      tidy \
      xsl \
      zip \
      mbstring \
      curl

RUN pecl install \
      amqp-2.1.2 \
      igbinary-3.2.16 \
      mongodb-1.21.0 \
      msgpack-3.0.0 \
      oauth-2.0.9 \
      redis-6.2.0 \
      timezonedb-2025.2 \
    && docker-php-ext-enable \
      amqp \
      igbinary \
      mongodb \
      msgpack \
      oauth \
      redis \
      timezonedb

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
RUN sed -i -e 's/;date.timezone\s*=\s*/date.timezone = "UTC"/g' "$PHP_INI_DIR/php.ini" \
    && sed -i -e 's/;opcache.enable=1/opcache.enable=1/g' "$PHP_INI_DIR/php.ini" \
    && sed -i -e 's/;opcache.memory_consumption=128/opcache.memory_consumption=256/g' "$PHP_INI_DIR/php.ini" \
    && sed -i -e 's/;opcache.max_accelerated_files=10000/opcache.max_accelerated_files=20000/g' "$PHP_INI_DIR/php.ini" \
    && sed -i -e 's/;opcache.validate_timestamps=1/opcache.validate_timestamps=0/g' "$PHP_INI_DIR/php.ini" \
    && sed -i -e 's/memory_limit\s*=\s*128/memory_limit = 512/g' "$PHP_INI_DIR/php.ini" \
    && sed -i -e 's/max_execution_time\s*=\s*30/max_execution_time = 120/g' "$PHP_INI_DIR/php.ini" \
    && sed -i -e 's/post_max_size\s*=\s*8/post_max_size = 64/g' "$PHP_INI_DIR/php.ini" \
    && sed -i -e 's/upload_max_filesize\s*=\s*2/upload_max_filesize = 64/g' "$PHP_INI_DIR/php.ini"

RUN curl -L -s https://getcomposer.org/download/${COMPOSER_VERSION}/composer.phar -o /usr/local/bin/composer \
    && chmod +x /usr/local/bin/composer

### Supervisor
COPY supervisord.conf /etc/supervisor/conf.d/webapp.conf

### Apache
COPY fcgi.conf /etc/apache2/conf-available/
COPY vhost.conf /etc/apache2/sites-available/webapp.conf
COPY up.sh /usr/local/bin/up.sh

RUN a2enmod \
      actions \
      proxy \
      proxy_fcgi \
      remoteip \
      rewrite \
    && a2dissite 000-default \
    && a2ensite webapp \
    && a2enconf fcgi

RUN sed -i -e 's|ErrorLog ${APACHE_LOG_DIR}/error.log|ErrorLog /proc/self/fd/2|g' /etc/apache2/apache2.conf

RUN curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | bash \
    && apt-get update \
    && apt-get install -y symfony-cli

# Remove development libraries and build tools after pecl extension being installed
RUN apt purge -y \
      libffi-dev \
      libicu-dev \
      libjpeg62-turbo-dev \
      libjpeg-dev \
      libmagickwand-dev \
      libmagickcore-dev \
      libonig-dev \
      libpng-dev \
      librabbitmq-dev \
      libtidy-dev \
      libxml2-dev \
      libxslt-dev \
      libzip-dev \
      libcurl4-openssl-dev \
      autoconf \
      dpkg-dev \
      file \
      g++ \
      gcc \
      libc-dev \
      make \
      pkg-config \
      re2c \
      wget && \
      apt clean

# Creating folders for the volumes and changing permissions
RUN mkdir -p /app


EXPOSE 80

CMD ["/usr/bin/bash"]
