FROM php:7.3-cli-alpine

LABEL product=auth-swoole-server

ENV PHPREDIS_VER=5.1.1 SWOOLE_VER=4.4.16

ARG CN="0"
ARG INTRANET="0"

# install modules
RUN set -eux \
    && ([ "${CN}" = "0" ] || sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories) \
    && apk --no-cache update \
    && apk add --no-cache --virtual .fetch-deps wget ${PHPIZE_DEPS} \
    && apk add --no-cache libstdc++ openssl-dev \
# install php modules
    && docker-php-source extract \
    && docker-php-ext-install -j$(nproc) sockets pcntl \
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
    && apk del --no-network .fetch-deps

# set China timezone
RUN set -eux \
    && apk add --no-cache tzdata \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone

