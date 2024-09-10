FROM php:7.4-apache

RUN set -ex; \
        apt-get update; \
        \
        savedAptMark="$(apt-mark showmanual)"; \
        \
        apt-get install -y --no-install-recommends \
                libfreetype6-dev \
                libicu-dev \
                libjpeg62-turbo-dev \
                libldap2-dev \
                libmagickwand-dev \
                libpng-dev \
                libpq-dev \
                libwebp-dev \
                libzip-dev \
                libcurl4-openssl-dev \
                pkg-config \
                zlib1g-dev \
                libssl-dev \
                libgmp-dev \
                libc-client-dev libkrb5-dev \
                libxml2-dev \
        ; \
        debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)"; \
        docker-php-ext-configure gd \
                --with-webp \
                --with-jpeg \
                --with-freetype; \
        docker-php-ext-configure ldap --with-libdir="lib/$debMultiarch"; \
        docker-php-ext-configure imap --with-kerberos --with-imap-ssl; \
        docker-php-ext-install \
                exif \
                imap \
                gmp \
                soap \
                gd \
                intl \
                ldap \
                pdo_mysql \
                pdo_pgsql \
                zip \
                mysqli \
                pcntl \
                bcmath \
                opcache \
        ; \
        pecl install imagick; \
        pecl install redis; \
        pecl install mongodb; \
        pecl install mailparse; \
        docker-php-ext-enable mongodb redis imagick mailparse; \
        \
        # do clean
        apt-mark auto '.*' > /dev/null; \
        apt-mark manual $savedAptMark; \
        ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
                | awk '/=>/ { print $3 }' \
                | sort -u \
                | xargs -r dpkg-query -S \
                | cut -d: -f1 \
                | sort -u \
                | xargs -rt apt-mark manual; \
        \
        apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
        \
        # add runtime tools.
        apt-get install -y --no-install-recommends \
        rsync wget curl net-tools procps unzip; \
        \
        rm -rf /var/lib/apt/lists/* ; \
        \
        # add composer.phar
        wget -qO /tmp/composer-installer.php https://getcomposer.org/installer ; \
        php /tmp/composer-installer.php --install-dir=/usr/local/bin/ --filename=composer ; \
        rm /tmp/composer-installer.php; \
        \
        # enable apache htaccess
        a2enmod rewrite

ADD docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["apache2-foreground"]
