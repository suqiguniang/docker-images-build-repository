#!/bin/bash
set -e

cd /hexo

# 后台运行 hexo server（监听 4000 端口）
hexo server -p 4000 &

# 前台运行 nginx，保持容器存活
exec nginx -g "daemon off;"
