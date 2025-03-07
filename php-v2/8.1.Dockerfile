FROM php:8.1.31-fpm-bookworm

LABEL product=php-swoole

ENV PHPREDIS_VER=6.1.0
ENV SWOOLE_VER=5.1.7
ENV XLSWRITER_VER=1.5.8

ENV COMPOSER_ALLOW_SUPERUSER=1

ARG CN="0"
ARG INTRANET="0"

ARG DEBIAN_FRONTEND=noninteractive

ENV PHP_EXT_INSTALLER_VERSION=2.7.27
ENV COMPOSER_VERSION=2.8.6

ENV TINI_VERSION=v0.19.0

RUN set -eux \
    && ([ "${CN}" = "0" ] || sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list.d/debian.sources)

ADD https://github.com/mlocati/docker-php-extension-installer/releases/download/${PHP_EXT_INSTALLER_VERSION}/install-php-extensions /usr/local/bin/install-php-extensions
RUN chmod +x /usr/local/bin/install-php-extensions

RUN install-php-extensions zip bz2 zstd
RUN install-php-extensions igbinary
RUN install-php-extensions sockets bcmath pdo pdo_mysql pcntl
RUN install-php-extensions gd imagick
RUN install-php-extensions exif imap intl

RUN install-php-extensions redis-${PHPREDIS_VER}
RUN install-php-extensions xlswriter-${XLSWRITER_VER}

RUN install-php-extensions ffi

# install
RUN set -eux \
    && apt update \
    && apt install --no-install-recommends -y \
     ca-certificates \
     libssl-dev \
     libzip-dev libbrotli-dev \
     libcurl4-openssl-dev \
     libc-ares-dev \
     libpq-dev \
# imagemagick & convert
     imagemagick \
# install php modules
    && docker-php-source extract \
# compile php modules
    && cd /usr/src/php/ext \
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
    && php --ri gd \
    && php --ri imap \
    # for IM 6
    && convert -version

RUN set -eux \
# set china timezone
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
# php config
    && mv "${PHP_INI_DIR}/php.ini-production" "${PHP_INI_DIR}/php.ini"

# [Composer](https://getcomposer.org/download/)
ADD https://getcomposer.org/download/${COMPOSER_VERSION}/composer.phar /usr/bin/composer
RUN chmod +x /usr/bin/composer \
    && composer --verbose

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
