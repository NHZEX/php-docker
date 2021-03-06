FROM php:7.4.15-cli

LABEL product=auth-swoole-server

ENV PHPREDIS_VER=5.3.3 SWOOLE_VER=4.5.11

ARG CN="0"
ARG INTRANET="0"

# install modules
RUN set -eux \
    && ([ "${CN}" = "0" ] || sed -i "s@http://deb.debian.org@http://mirrors.tuna.tsinghua.edu.cn@g" /etc/apt/sources.list) \
    && ([ "${CN}" = "0" ] || sed -i "s|security.debian.org/debian-security|mirrors.tuna.tsinghua.edu.cn/debian-security|g" /etc/apt/sources.list) \
    && apt update \
    && apt install -y wget git libssl-dev libzip-dev \
# install php modules
    && docker-php-source extract \
    && docker-php-ext-install -j$(nproc) sockets pcntl zip \
# compile php modules
    && cd /usr/src/php/ext \
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
# install php swoole
    && (if [ "${INTRANET}" = "0" ]; then \
        pecl bundle swoole-${SWOOLE_VER} \
        ; \
    else \
        wget -P /tmp ${INTRANET}/swoole-${SWOOLE_VER}.tgz  \
        && pecl bundle /tmp/swoole-${SWOOLE_VER}.tgz \
        ; \
    fi) \
    && docker-php-ext-configure swoole --enable-openssl --enable-http2 \
    && docker-php-ext-install -j$(nproc) swoole \
# all done
    && php -v \
    && php -m \
# clear up
    && docker-php-source delete \
    && apt-get --purge remove -y wget \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux \
# set china timezone
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
# php config
    && mv "${PHP_INI_DIR}/php.ini-production" "${PHP_INI_DIR}/php.ini"

