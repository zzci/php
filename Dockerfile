FROM alpine:3.13 as builder

WORKDIR /work

# download php
ENV PHP_URL="https://www.php.net/distributions/php-7.4.20.tar.gz" 
ENV SWOOLE_URL "https://pecl.php.net/get/swoole-4.6.7.tgz"
ENV INOTIFY_URL "https://pecl.php.net/get/inotify-3.0.0.tgz"
ENV REDIS_URL "https://pecl.php.net/get/redis-5.3.4.tgz"
ENV MONGODB_URL "https://pecl.php.net/get/mongodb-1.9.1.tgz"
ENV CURL_URL "https://curl.haxx.se/download/curl-7.76.1.tar.gz"
ENV LIBZIP_URL "https://libzip.org/download/libzip-1.7.3.tar.gz"
ADD $PHP_URL /work/src/php.tar.gz
ADD $SWOOLE_URL /work/src/swoole.tar.gz
ADD $INOTIFY_URL /work/src/inotify.tar.gz
ADD $REDIS_URL /work/src/redis.tar.gz
ADD $MONGODB_URL /work/src/mongodb.tar.gz
ADD $CURL_URL /work/src/curl.tar.gz
ADD $LIBZIP_URL /work/src/libzip.tar.gz


RUN set -eux; \
  mkdir -p /work/app/php ;\
  tar -xzf /work/src/php.tar.gz -C /work/app/php --strip-components=1 ;\
  \
  mkdir -p /work/app/curl ;\
  tar -xzf /work/src/curl.tar.gz -C /work/app/curl --strip-components=1 ;\
  \
  mkdir -p /work/app/libzip ;\
  tar -xzf /work/src/libzip.tar.gz -C /work/app/libzip --strip-components=1 ;\
  \
  mkdir -p /work/app/php/ext/swoole ;\
  tar -xzf /work/src/swoole.tar.gz -C /work/app/php/ext/swoole --strip-components=1 ;\
  \
  mkdir -p /work/app/php/ext/inotify ;\
  tar -xzf /work/src/inotify.tar.gz -C /work/app/php/ext/inotify --strip-components=1 ;\
  \
  mkdir -p /work/app/php/ext/redis ;\
  tar -xzf /work/src/redis.tar.gz -C /work/app/php/ext/redis --strip-components=1 ;\
  \
  mkdir -p /work/app/php/ext/mongodb ;\
  tar -xzf /work/src/mongodb.tar.gz -C /work/app/php/ext/mongodb --strip-components=1 ;\
  \
  apk add --no-cache --virtual .build-deps \
  gcc g++ autoconf libstdc++ linux-headers make curl \
  m4 libgcc binutils ncurses  \
  cmake zlib-dev zlib-static  \
  oniguruma-dev openssl-libs-static openssl-dev openssl \
  libpng-dev libpng-static \
  c-ares-static c-ares-dev \
  icu-dev icu-static \
  sqlite-dev sqlite-static \
  libsodium-static libsodium-dev \
  libzip-dev  xz-dev libxml2-dev \
  ncurses-static readline-static readline-dev \
  gdbm-dev \
  libgss-dev && \
  cd /work/app/curl  && \
  ls -ltrh  && \
  CC=gcc CXX=g++ CFLAGS=-fPIC CPPFLAGS=-fPIC ./configure \
     --without-nghttp2 \
     --with-ssl=/usr \
     --with-pic=pic \
     --enable-ipv6 \
     --enable-shared=no \
     --without-libidn2 \
     --disable-ldap \
     --without-libpsl \
     --without-lber \
     --enable-ares && \
  make -j4 && \
  make install && \
  echo "编译 curl 完成！" && \
  cd /work/app/libzip  && \
  sed -i '65s/ON/OFF/' CMakeLists.txt && \
  rm -rf build && \
  mkdir build && \
  cd build && \
  cmake .. && \
  make -j8 && \
  make install && \
  echo "编译 libzip 完成！" && \
  cd /work/app/php && \
  echo $'AC_DEFUN([PHP_CHECK_LIBRARY], [ \n\
  $3 \n\
])' > ac_override_1  && \
  echo $'AC_DEFUN([PHP_CHECK_LIBRARY], [ \n\
  save_old_LDFLAGS=$LDFLAGS \n\
  ac_stuff="$5" \n\
  save_ext_shared=$ext_shared \n\
  ext_shared=yes \n\
  PHP_EVAL_LIBLINE([$]ac_stuff, LDFLAGS) \n\
  AC_CHECK_LIB([$1],[$2],[ \n\
    LDFLAGS=$save_old_LDFLAGS \n\
    ext_shared=$save_ext_shared \n\
    $3 \n\
  ],[ \n\
    LDFLAGS=$save_old_LDFLAGS \n\
    ext_shared=$save_ext_shared \n\
    unset ac_cv_lib_$1[]_$2 \n\
    $4 \n\
  ]) \n\
])' > ac_override_2 && \
  cat ac_override_1 ext/curl/config.m4 ac_override_2 > /tmp/aa && \
  mv /tmp/aa "ext/curl/config.m4" && \
  rm -rf ac_override_1 ac_override_2 && \
  sed -i '41,76s/^/  dnl /g' ext/readline/config.m4 && \
  PKG_CONFIG_PATH="/usr/lib/pkgconfig" && \
  ./buildconf --force && \
  # PKG_CONFIG_PATH=$PKG_CONFIG_PATH ./configure $(php_get_configure_args) && \
  echo $PKG_CONFIG_PATH && \
  PKG_CONFIG_PATH=$PKG_CONFIG_PATH ./configure LDFLAGS=-static  \
    --prefix=/usr/local \
    --disable-all \
    --enable-shared=no \
    --enable-static=yes \
    --enable-inline-optimization \
    --with-layout=GNU \
    --enable-calendar \
    --enable-ctype \
    --enable-filter \
    --enable-openssl \
    --enable-bcmath \
    --with-openssl-dir=/usr \
    --enable-openssl \
    --with-openssl \
    --with-iconv \
    --enable-json \
    --enable-mbstring \
    --enable-phar \
    --enable-pdo \
    --with-pdo-mysql=mysqlnd \
    --enable-sockets \
    --enable-swoole \
    --disable-inotify \
    --enable-redis \
    --with-gdbm \
    --disable-redis-session \
    --enable-simplexml \
    --enable-dom \
    --with-libxml \
    --enable-xmlwriter \
    --enable-xmlreader \
    --with-zlib \
    --enable-posix \
    --enable-mysqlnd \
    --enable-tokenizer \
    --with-curl \
    --with-pear=no \
    --disable-cgi \
    --disable-phpdbg \
    --with-sodium \
    --enable-exif \
    --enable-fileinfo \
    --enable-ftp \
    --enable-session \
    --with-mysqli \
    --with-sqlite3 \
    --with-pdo-sqlite \
    --enable-gd \
    --enable-pcntl \
    --enable-mongodb \
    --with-mongodb-sasl=no \
    --with-mongodb-client-side-encryption=no \
    --enable-intl \
    --disable-opcache \
    --with-zip \
    --with-readline; \
  sed -ie 's/-export-dynamic//g' Makefile && \
  sed -ie 's/-lzip/-lzip -llzma -lssl -lcrypt -lcrypto -lreadline -licuuc -licudata -lstdc++ -lgdbm -lgss -lncursesw/g' Makefile && \
  sed -ie 's/-o $(SAPI_CLI_PATH)/-all-static -o $(SAPI_CLI_PATH)/g' Makefile && \
  sed -ie 's/swoole_clock_gettime(CLOCK_REALTIME/clock_gettime(CLOCK_REALTIME/g' ext/swoole/include/swoole.h && \
  make LDFLAGS=-ldl -j8 && \
  make install && \
  strip "/usr/local/bin/php" && \
  echo "编译 php 完成！" && \
  rm -rf /work/src/*.tar.gz && \
 	apk del --no-network .build-deps

FROM alpine:latest  
WORKDIR /work/
COPY --from=builder /usr/local/bin/php /usr/local/bin/php
