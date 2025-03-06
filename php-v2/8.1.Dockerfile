FROM php:8.1.31-fpm-bookworm

LABEL product=php-swoole

ENV PHPREDIS_VER=6.1.0
ENV SWOOLE_VER=5.1.7
ENV XLSWRITER_VER=1.5.8

ENV COMPOSER_ALLOW_SUPERUSER=1

ARG CN="0"
ARG INTRANET="0"

ARG DEBIAN_FRONTEND=noninteractive

RUN set -eux \
    && ([ "${CN}" = "0" ] || sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list.d/debian.sources)

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

# install
RUN set -eux \
    && apt update \
    && apt install --no-install-recommends -y \
     ca-certificates \
     libssl-dev \
     libzip-dev zlib1g-dev libzstd-dev \
     libjpeg-dev libpng-dev libwebp-dev libfreetype6-dev libxpm-dev \
     libc-client-dev libkrb5-dev \
     libicu-dev \
     libmagickwand-dev \
     libcurl4-openssl-dev \
     libc-ares-dev \
     libpq-dev \
     imagemagick \
# install php modules
    && docker-php-source extract \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install -j$(nproc) \
     bcmath \
     bz2 \
     sockets \
     exif \
     gd \
     imap \
     intl \
     pcntl \
     zip \
     pdo \
     pdo_mysql \
# compile php modules
    && cd /usr/src/php/ext \
# install igbinary
    && pecl install igbinary \
    && docker-php-ext-enable igbinary \
# install zstd
    && pecl install zstd \
    && docker-php-ext-enable zstd \
# install php redie
    && (if [ "${INTRANET}" = "0" ]; then \
        pecl install redis-${PHPREDIS_VER} \
        ; \
    else \
        wget -P /tmp ${INTRANET}/redis-${PHPREDIS_VER}.tgz  \
        && pecl install /tmp/redis-${PHPREDIS_VER}.tgz \
        ; \
    fi) \
    && docker-php-ext-enable redis \
# install imagick
    && pecl install imagick \
    && docker-php-ext-enable imagick \
# install xlswriter \
    && (if [ "${INTRANET}" = "0" ]; then \
        pecl bundle xlswriter-${XLSWRITER_VER} \
        ; \
    else \
        wget -P /tmp ${INTRANET}/xlswriter-${XLSWRITER_VER}.tgz  \
        && pecl bundle /tmp/xlswriter-${XLSWRITER_VER}.tgz \
        ; \
    fi) \
    && docker-php-ext-configure xlswriter --enable-reader \
    && docker-php-ext-install -j$(nproc) xlswriter \
    && docker-php-ext-enable xlswriter \
# install php swoole
    && (if [ "${INTRANET}" = "0" ]; then \
        pecl bundle swoole-${SWOOLE_VER} \
        ; \
    else \
        wget -P /tmp ${INTRANET}/swoole-${SWOOLE_VER}.tgz  \
        && pecl bundle /tmp/swoole-${SWOOLE_VER}.tgz \
        ; \
    fi) \
    && docker-php-ext-configure swoole \
      --enable-sockets \
      --enable-openssl \
      --enable-mysqlnd \
      --enable-sockets \
      --enable-swoole-curl \
      --enable-swoole-pgsql \
      --enable-cares \
      --enable-brotli \
    && docker-php-ext-install -j$(nproc) swoole \
# opcache \
    && echo "zend_extension=opcache.so" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
    && echo "opcache.enable_cli=1" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
# clear up
    && docker-php-source delete \
#    && apt-get --purge remove -y wget \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux \
# check
    && php -v \
    && php -m \
    && php --ri curl \
    && php --ri redis \
    && php --ri xlswriter \
    && php --ri swoole \
    && php --ri imagick \
    # for IM 6
    && convert -version

RUN set -eux \
# set china timezone
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
# php config
    && mv "${PHP_INI_DIR}/php.ini-production" "${PHP_INI_DIR}/php.ini"

RUN curl -sfL https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
    && chmod +x /usr/bin/composer \
    && composer --verbose

ENV TINI_VERSION=v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /sbin/tini
RUN chmod +x /sbin/tini

ENV PHP_MEMORY_LIMIT=512M

ENV UID=1000
ENV GID=1000

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY ./etc/php.conf.d/zz-conf.ini "/usr/local/etc/php/conf.d/"
COPY ./etc/fpm.conf.d/zz-fpm.conf "/usr/local/etc/php-fpm.d/"

#ENTRYPOINT ["entrypoint.sh"]
ENTRYPOINT ["/sbin/tini", "--", "entrypoint.sh"]
