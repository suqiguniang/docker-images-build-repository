#!/bin/bash
set -e

cd /hexo

# 使用 npx 运行本地安装的 hexo
npx hexo server -p 4000 &

# 等待 hexo 启动
sleep 2

# 前台运行 nginx
exec nginx -g "daemon off;"
