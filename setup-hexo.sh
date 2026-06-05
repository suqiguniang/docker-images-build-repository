#!/bin/bash
set -e

# ==========================================
# Hexo + Butterfly 一键安装脚本（非 Docker）
# 基于 hexo-docker 项目内容
# ==========================================

# ---------- 颜色输出 ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info()  { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()   { echo -e "${RED}[ERROR]${NC} $1"; }

# ---------- 配置参数 ----------
HEXO_DIR="${HEXO_DIR:-$HOME/hexo}"
NPM_REGISTRY="${NPM_REGISTRY:-https://registry.npmmirror.com}"

# ==========================================
# 第一步：通过 nvm 安装 Node 24
# ==========================================
install_node() {
    # 先检查 node 是否已经是 v24
    if command -v node &>/dev/null; then
        local node_ver
        node_ver=$(node -v | sed 's/v//' | cut -d. -f1)
        if [ "$node_ver" -ge 24 ] 2>/dev/null; then
            ok "Node.js $(node -v) 已存在，跳过安装"
            return
        fi
        warn "当前 Node.js $(node -v)，需要 v24，将通过 nvm 安装"
    fi

    # 检查 nvm 是否已安装
    export NVM_DIR="$HOME/.nvm"
    if [ ! -d "$NVM_DIR" ]; then
        info ">>> 安装 nvm..."
        curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
    fi

    # 加载 nvm
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # 检查 nvm 是否已有 Node 24
    if nvm ls 24 &>/dev/null; then
        ok "Node.js 24 已通过 nvm 安装，跳过"
    else
        info ">>> 安装 Node.js 24..."
        nvm install 24
    fi

    nvm use 24
    nvm alias default 24

    command -v node >/dev/null 2>&1 || {
        err "Node.js 安装失败"
        exit 1
    }

    info ">>> Node.js: $(node -v), npm: $(npm -v)"
    ok "Node.js 24 就绪"
}

# ==========================================
# 第二步：安装 git 等基础工具
# ==========================================
install_deps() {
    local need_install=false
    for cmd in git wget; do
        if ! command -v "$cmd" &>/dev/null; then
            need_install=true
            break
        fi
    done

    if [ "$need_install" = false ]; then
        ok "git、wget 均已存在，跳过"
        return
    fi

    info ">>> 安装 git、wget..."
    if command -v apt-get &>/dev/null; then
        apt-get update -qq && apt-get install -y -qq git wget
    elif command -v yum &>/dev/null; then
        yum install -y git wget
    elif command -v apk &>/dev/null; then
        apk add --no-cache git wget
    else
        warn "请手动安装 git 和 wget"
    fi
    ok "基础工具检查完成"
}

# ==========================================
# 第二步：初始化 Hexo 站点
# ==========================================
init_hexo() {
    if [ -d "$HEXO_DIR" ] && [ -f "$HEXO_DIR/_config.yml" ]; then
        warn "目标目录 $HEXO_DIR 已存在 Hexo 站点，跳过初始化"
        return
    fi

    # 检测 hexo-cli
    if ! command -v hexo &>/dev/null; then
        info ">>> 安装 Hexo CLI..."
        npm install -g hexo-cli
    else
        ok "Hexo CLI 已存在"
    fi

    info ">>> 创建 Hexo 站点在 $HEXO_DIR..."
    mkdir -p "$HEXO_DIR"
    cd "$HEXO_DIR"
    GIT_SSL_NO_VERIFY=1 hexo init .
    npm install --registry="$NPM_REGISTRY"

    ok "Hexo 站点初始化完成"
}

# ==========================================
# 第三步：安装主题和插件
# ==========================================
install_plugins() {
    cd "$HEXO_DIR"

    # 检测核心插件是否已装（蝴蝶主题 + 任一常用插件）
    if [ -d "node_modules/hexo-theme-butterfly" ] && [ -d "node_modules/hexo-generator-search" ]; then
        ok "主题和插件已安装，跳过"
    else
        info ">>> 安装 Butterfly 主题..."
        npm install hexo-theme-butterfly --save

        info ">>> 安装常用插件..."
        npm install hexo-server hexo-deployer-git \
            hexo-generator-search \
            hexo-generator-feed \
            hexo-generator-sitemap \
            hexo-butterfly-tag-plugins-plus \
            hexo-symbols-count-time \
            hexo-wordcount \
            hexo-tag-aplayer \
            --save --registry="$NPM_REGISTRY"
    fi

    # 确保主题配置正确（每次都执行，幂等操作）
    info ">>> 配置主题为 butterfly..."
    sed -i 's/^theme:.*/theme: butterfly/' _config.yml

    # 确保 .bin 目录可执行
    chmod -R +x ./node_modules/.bin/ 2>/dev/null || true

    ok "主题和插件就绪"
}

# ==========================================
# 第四步：生成默认 Butterfly 配置文件
# ==========================================
create_butterfly_config() {
    local CONFIG="$HEXO_DIR/_config.butterfly.yml"

    if [ -f "$CONFIG" ]; then
        warn "$CONFIG 已存在，跳过创建"
        return
    fi

    info ">>> 生成默认 Butterfly 主题配置..."
    cat > "$CONFIG" << 'BUTTERFLY'
# ==========================================
# Butterfly 主题配置
# 更多选项: https://butterfly.js.org/
# ==========================================

# 导航设置
nav:
  logo:
  display_title: true
  display_post_title: true
  fixed: false

# 代码块设置
code_blocks:
  theme: light
  macStyle: false
  height_limit: false
  word_wrap: false
  copy: true
  language: true
  shrink: false
  fullpage: false

# 社交链接
social:

# favicon
favicon: /img/favicon.png

# 头像
avatar:
  img: https://i.loli.net/2021/02/24/5O1day2nriDzjSu.png
  effect: false

# 首页设置
index_layout: 1
index_post_content:
  method: 3
  length: 500

# 目录
toc:
  post: true
  page: false
  number: true
  expand: false
  style_simple: false
  scroll_percent: true

# 版权
post_copyright:
  enable: true
  decode: false
  license: CC BY-NC-SA 4.0
  license_url: https://creativecommons.org/licenses/by-nc-sa/4.0/

# 相关文章
related_post:
  enable: true
  limit: 6
  date_type: created

# 页脚
footer:
  owner:
    enable: true
    since: 2019
  custom_text:
  copyright:
    enable: true
    version: true

# 侧边栏
aside:
  enable: true
  hide: false
  button: true
  mobile: true
  position: right
  card_author:
    enable: true
    description:
    button:
      enable: true
      icon: fab fa-github
      text: Follow Me
      link: https://github.com/xxxxxx
  card_announcement:
    enable: true
    content: Welcome to my Blog
  card_recent_post:
    enable: true
    limit: 5
    sort: date
  card_categories:
    enable: true
    limit: 8
    expand: none
  card_tags:
    enable: true
    limit: 40
    color: false
    orderby: random
    order: 1
  card_archives:
    enable: true
    type: monthly
    format: MMMM YYYY
    order: -1
    limit: 8
  card_webinfo:
    enable: true
    post_count: true
    last_push_date: true

# 暗黑模式
darkmode:
  enable: true
  button: true
  autoChangeMode: false

# 图片设置
cover:
  index_enable: true
  aside_enable: true
  archives_enable: true
  position: both

error_img:
  flink: /img/friend_404.gif
  post_page: /img/404.jpg

# 搜索
search:
  use:
  placeholder:

# 评论
comments:
  use:
  text: true
  lazyload: false
  count: false
  card_post_count: false

# 灯箱
lightbox:

# 标签外挂
note:
  style: flat
  icons: true
  border_radius: 3
  light_bg_offset: 0

# 其他
pjax:
  enable: false
snackbar:
  enable: false
  position: bottom-left
instantpage: false
lazyload:
  enable: false
  field: site
pwa:
  enable: false
BUTTERFLY
    ok "$CONFIG 已创建"
}

# ==========================================
# 第五步：生成静态文件
# ==========================================
build_site() {
    cd "$HEXO_DIR"
    info ">>> 生成静态文件..."
    ./node_modules/.bin/hexo generate
    ok "静态文件生成完成"
}

# ==========================================
# 第七步：创建便捷命令
# ==========================================
create_aliases() {
    local BIN_DIR="$HOME/.local/bin"
    mkdir -p "$BIN_DIR"

    info ">>> 创建便捷命令..."

    cat > "$BIN_DIR/hexo-update" << 'CMD'
#!/bin/bash
cd "$HOME/hexo" 2>/dev/null || cd /hexo 2>/dev/null || { echo "未找到 hexo 目录"; exit 1; }
./node_modules/.bin/hexo generate
echo "静态文件已更新！"
CMD
    chmod +x "$BIN_DIR/hexo-update"

    cat > "$BIN_DIR/hexo-preview" << 'CMD'
#!/bin/bash
cd "$HOME/hexo" 2>/dev/null || cd /hexo 2>/dev/null || { echo "未找到 hexo 目录"; exit 1; }
./node_modules/.bin/hexo server -p 4000
CMD
    chmod +x "$BIN_DIR/hexo-preview"

    # 确保 PATH 中有 ~/.local/bin
    case ":$PATH:" in
        *":$BIN_DIR:"*) ;;
        *) echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$HOME/.bashrc"
           info "已将 $BIN_DIR 添加到 PATH (请执行 source ~/.bashrc 生效)" ;;
    esac

    ok "已创建命令: hexo-update（重新生成）, hexo-preview（本地预览）"
}

# ==========================================
# 主流程
# ==========================================
main() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  Hexo + Butterfly 一键安装脚本${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""

    install_node
    install_deps
    init_hexo
    install_plugins
    create_butterfly_config
    build_site
    create_aliases

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  安装完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "  Node.js:  $(node -v)"
    echo "  博客目录:  $HEXO_DIR"
    echo "  文章目录:  $HEXO_DIR/source/_posts/"
    echo "  配置文件:  $HEXO_DIR/_config.yml"
    echo "  主题配置:  $HEXO_DIR/_config.butterfly.yml"
    echo ""
    echo "  预览博客:  hexo-preview  →  http://localhost:4000"
    echo "  重新生成:  hexo-update"
    echo ""
    echo "  执行 source ~/.bashrc 让命令生效"
    echo "  然后写文章到 $HEXO_DIR/source/_posts/，运行 hexo-update"
    echo ""
}

main
