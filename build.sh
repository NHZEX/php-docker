#!/usr/bin/env bash

IMAGE_VERSION="1.7"

docker build --build-arg CN=1 --build-arg INTRANET=http://192.168.138.166/files -t swoole-server:${IMAGE_VERSION} .