#!/bin/bash
set -e

cd /hexo

# ---------- 自动初始化 Hexo 站点（仅首次）----------
if [ ! -f "_config.yml" ]; then
    echo ">>> 首次启动，正在初始化 Hexo 站点..."
    # 初始化站点（会生成 node_modules）
    hexo init . && npm install

    echo ">>> 安装 Butterfly 主题..."
    npm install hexo-theme-butterfly --save
    sed -i 's/^theme:.*/theme: butterfly/' _config.yml

    echo ">>> 安装常用插件..."
    npm install hexo-deployer-git hexo-generator-search \
        hexo-generator-feed hexo-generator-sitemap --save

    # 确保 .bin 目录下的所有可执行文件都有执行权限
    chmod -R +x ./node_modules/.bin/

    echo ">>> 生成静态文件..."
    ./node_modules/.bin/hexo generate

    echo ">>> 初始化完成！"
else
    echo ">>> 检测到已有站点，跳过初始化。"
    # 即使非首次，也确保权限（防止挂载卷权限异常）
    chmod -R +x ./node_modules/.bin/ 2>/dev/null || true
fi

# ---------- 启动 hexo server（后台）----------
echo ">>> 启动 hexo server (端口 4000)..."
./node_modules/.bin/hexo server -p 4000 &

# ---------- 启动 nginx（前台）----------
echo ">>> 启动 nginx (端口 80)..."
exec nginx -g "daemon off;"
