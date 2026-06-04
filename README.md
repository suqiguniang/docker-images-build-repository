# Hexo Docker - Butterfly Theme

将 Hexo 博客（Butterfly 主题）打包为 Docker 镜像，支持通过 volume 挂载博客内容，每次启动自动执行 `hexo generate`。

## 项目结构

```
.
├── dockerfile                       # 多阶段构建 Dockerfile
├── docker-compose.yml               # Docker Compose 编排
├── nginx.conf                       # Nginx 静态文件服务配置
├── start.sh                         # 容器启动脚本
├── hexo-container-key.pub           # （可选）容器 SSH 公钥
├── .github/workflows/docker-build.yml  # GitHub Actions 自动构建
└── README.md
```

## 架构说明

### 多阶段构建（Dockerfile）

**第一阶段 - 构建（builder）：**
- 基于 `node:lts-slim`，安装 wget、git、nginx
- 安装 Hexo CLI，执行 `hexo init` 初始化站点
- 安装 Butterfly 主题及常用插件
- 执行 `hexo generate` 生成初始静态文件
- 清理 npm 缓存以减小镜像体积

**第二阶段 - 运行（runtime）：**
- 同样基于 `node:lts-slim`，仅安装 nginx
- 从 builder 阶段复制完整的 Hexo 站点（含 node_modules、public 等）
- 配置 Nginx 以 `/hexo/public` 为根目录提供静态文件服务
- 复制启动脚本 `start.sh` 作为容器入口

### 数据持久化（docker-compose.yml）

容器仅挂载**必要的数据**到 `/hexo` 目录：

```yaml
volumes:
  - ./source:/hexo/source                  # 博客文章源文件
  - ./_config.yml:/hexo/_config.yml        # Hexo 主配置
  - ./_config.butterfly.yml:/hexo/_config.butterfly.yml  # Butterfly 主题配置
```

其余文件（node_modules、themes、scaffolds、public 等）由镜像自身提供。

### 启动流程（start.sh）

每次容器启动时：

1. 检测 `/hexo/_config.yml` 是否存在
   - **不存在** → 自动执行 `hexo init` 初始化站点 + 安装 Butterfly 主题和插件
   - **存在** → 跳过初始化，直接进入下一步
2. 运行 `hexo generate` 生成最新的静态文件
3. 后台启动 Hexo Server（端口 4000，方便调试预览）
4. 前台启动 Nginx（端口 80，对外提供静态文件访问）

## 使用方法

### 前提条件

- Docker 和 Docker Compose 已安装
- 准备好 Hexo 博客的：
  - `source/` 文件夹（博客文章）
  - `_config.yml`（Hexo 主配置，需设置 `theme: butterfly`）
  - `_config.butterfly.yml`（Butterfly 主题配置）

### 快速启动

1. 将上述文件放在 `docker-compose.yml` 同级目录下

2. 启动容器：

```bash
docker compose up -d
```

3. 访问博客：

```
http://localhost:10086
```

Hexo Server（调试用）在端口 4000:

```
http://localhost:4000
```

### 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `NPM_REGISTRY` | `https://registry.npmmirror.com` | npm 镜像源 |
| `NODE_ENV` | `production` | Node 运行环境 |

## GitHub Actions 自动构建

`.github/workflows/docker-build.yml` 定义了一个 GitHub Actions 工作流：

- **触发方式：** 手动触发（`workflow_dispatch`）
- **构建镜像：** 基于项目根目录的 Dockerfile 构建
- **推送目标：** `ghcr.io/<用户名>/hexo-butterfly-static`
- **标签策略：**
  - `hexo` → 分支名标签
  - `sha-xxxxxx` → commit SHA 标签
  - `latest` → 仅在 `hexo` 分支推送时打上
- **产物下载：** 构建完成后将镜像打包为 `hexo-image.tar.gz` 上传到 Actions Artifact

### 手动触发构建

1. 进入 GitHub 仓库页面
2. 点击 **Actions** 标签
3. 选择 **Build and Push Hexo Static Image**
4. 点击 **Run workflow**

## 端口说明

| 端口 | 用途 |
|------|------|
| `10086` | Nginx 对外服务（生产环境） |
| `4000` | Hexo Server 调试预览 |

## 插件清单

| 插件 | 用途 |
|------|------|
| hexo-server | Hexo 本地调试服务器 |
| hexo-theme-butterfly | 主题 |
| hexo-deployer-git | Git 部署 |
| hexo-generator-search | 本地搜索 |
| hexo-generator-feed | RSS 订阅 |
| hexo-generator-sitemap | 搜索引擎站点地图 |
| hexo-butterfly-tag-plugins-plus | Butterfly 标签插件增强版 |
| hexo-symbols-count-time | 文章字数统计与阅读时长 |

## 注意事项

- 外部 `_config.yml` 中**必须**设置 `theme: butterfly`，否则会使用 Hexo 默认的 landscape 主题
- 容器内的 `node_modules`、`themes`、`scaffolds` 等由镜像构建时生成，不可通过 volume 覆盖
- 如需添加新插件，需更新 Dockerfile 并重新构建镜像
