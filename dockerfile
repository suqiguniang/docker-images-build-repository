# ========== 构建阶段 ==========
FROM node:lts-slim AS builder

# 按要求安装 wget、git、nginx
RUN apt-get update && \
    apt-get install -y --no-install-recommends wget git nginx && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /hexo

# 安装 Hexo CLI，初始化站点
RUN npm install -g hexo-cli
RUN hexo init . && npm install
ENV PATH="/usr/local/lib/node_modules/.bin:${PATH}"
# 安装 Butterfly 主题及常用插件
RUN npm install hexo-theme-butterfly --save && \
    sed -i 's/^theme:.*/theme: butterfly/' _config.yml

RUN npm install hexo-deployer-git hexo-generator-search \
    hexo-generator-feed hexo-generator-sitemap --save

# 编译静态文件
RUN hexo generate

# ========== 运行阶段 ==========
FROM node:lts-slim

# 仅保留 nginx
RUN apt-get update && \
    apt-get install -y --no-install-recommends nginx && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /hexo

# 复制完整的 Hexo 站点（含 public、node_modules、package.json 等）
COPY --from=builder /hexo /hexo

# 关键：清除默认配置
RUN rm -f /etc/nginx/sites-enabled/default /etc/nginx/conf.d/default.conf

# 复制 nginx 配置文件（静态文件服务）
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 复制启动脚本
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 80

CMD ["/start.sh"]
