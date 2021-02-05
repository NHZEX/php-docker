#!/usr/bin/env bash

docker build --build-arg CN=1 --build-arg INTRANET=http://192.168.138.166/files -t swoole-server:1.7 .