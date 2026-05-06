#!/bin/bash
set -e

cd /hexo

# ---------- 自动初始化 Hexo 站点（仅首次）----------
if [ ! -f "_config.yml" ]; then
    echo ">>> 首次启动，正在初始化 Hexo 站点..."
    hexo init . && npm install

    echo ">>> 安装 Butterfly 主题..."
    npm install hexo-theme-butterfly --save
    sed -i 's/^theme:.*/theme: butterfly/' _config.yml

    echo ">>> 安装常用插件..."
    npm install hexo-deployer-git hexo-generator-search \
        hexo-generator-feed hexo-generator-sitemap --save

    echo ">>> 生成静态文件..."
    hexo generate

    echo ">>> 初始化完成！"
else
    echo ">>> 检测到已有站点，跳过初始化。"
fi

# ---------- 启动 hexo server（后台）----------
echo ">>> 启动 hexo server (端口 4000)..."
hexo server -p 4000 &

# ---------- 启动 nginx（前台，保持容器存活）----------
echo ">>> 启动 nginx (端口 80)..."
exec nginx -g "daemon off;"
