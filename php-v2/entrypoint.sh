#!/bin/sh
set -e

# 从环境变量读取 UID/GID（默认值 1000）
USER_ID=${UID:-1000}
GROUP_ID=${GID:-1000}

export PHP_VER=${PHP_VERSION%.*}

# 创建组（如果不存在）
if ! getent group "$GROUP_ID" >/dev/null; then
  groupadd -g "$GROUP_ID" www-app
fi

# 创建用户（如果不存在）
if ! id -u "$USER_ID" >/dev/null 2>&1; then
  useradd --shell /bin/bash -u "$USER_ID" -g "$GROUP_ID" -o -c "" -m www-app
fi

# 确保用户主目录存在（某些应用需要）
export HOME=/home/www-app
mkdir -p "$HOME" && chown "$USER_ID:$GROUP_ID" "$HOME"

export PHP_SOCK_DIR=/var/run/php
mkdir -p "$PHP_SOCK_DIR" && chown "$USER_ID:$GROUP_ID" "$PHP_SOCK_DIR"

cat > /usr/local/etc/php-fpm.d/zz-www-over.conf << EOF
[www]
listen = ${PHP_SOCK_DIR}/php${PHP_VER}-fpm.sock
EOF

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- php "$@"
fi

exec "$@"