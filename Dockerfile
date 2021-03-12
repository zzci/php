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
                libzip-dev \
                libcurl4-openssl-dev \
                pkg-config \
                libssl-dev \
        ; \
        \
        debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)"; \
        docker-php-ext-configure gd; \
        docker-php-ext-configure ldap --with-libdir="lib/$debMultiarch"; \
        docker-php-ext-install \
                exif \
                gd \
                intl \
                ldap \
                pdo_mysql \
                pdo_pgsql \
                zip \
                mysqli \
                bcmath \
                opcache \
        ; \
        pecl install imagick; \
        printf "\n" | pecl install redis; \
        pecl install mongodb; \
        docker-php-ext-enable mongodb redis imagick; \
        \
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
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
        apt-get install -y --no-install-recommends \
        rsync wget curl net-tools procps unzip; \
        \
        rm -rf /var/lib/apt/lists/* ; \
# add composer.phar
        wget -qO /tmp/composer-installer.php https://getcomposer.org/installer ; \
        php /tmp/composer-installer.php --install-dir=/usr/local/bin/ --filename=composer ; \
        rm /tmp/composer-installer.php

ADD docker-entrypoint.sh /

COPY --from=zzci/init / /

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["apache2-foreground"]
