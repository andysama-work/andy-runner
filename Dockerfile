# Gitea Act Runner 自定义镜像
# 包含: Bun, Node.js, npm, Rust, wasm-pack
# 使用国内镜像源加速

FROM debian:bookworm-slim

LABEL maintainer="andy"
LABEL description="Gitea Runner with Bun, Node.js, Rust, wasm-pack"

# 避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive

# 设置环境变量
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:/root/.bun/bin:$PATH \
    BUN_INSTALL=/root/.bun

# 安装基础依赖 + Tauri 依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    git \
    openssh-client \
    build-essential \
    pkg-config \
    libssl-dev \
    unzip \
    # Tauri 依赖
    libgtk-3-dev \
    libwebkit2gtk-4.1-dev \
    libayatana-appindicator3-dev \
    librsvg2-dev \
    && rm -rf /var/lib/apt/lists/*

# 安装 Node.js
RUN curl -fsSL https://nodejs.org/dist/v20.11.0/node-v20.11.0-linux-x64.tar.xz | tar -xJ -C /usr/local --strip-components=1

# 安装 Bun
RUN curl -fsSL https://github.com/oven-sh/bun/releases/download/bun-v1.1.0/bun-linux-x64.zip -o bun.zip \
    && unzip bun.zip \
    && mv bun-linux-x64/bun /usr/local/bin/ \
    && chmod +x /usr/local/bin/bun \
    && rm -rf bun.zip bun-linux-x64

# 安装 Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable \
    && rustup target add wasm32-unknown-unknown

# 配置 Cargo
RUN mkdir -p $CARGO_HOME && echo '[net]\n\
git-fetch-with-cli = true' > $CARGO_HOME/config.toml

# 安装 wasm-pack
RUN cargo install wasm-pack

# 验证安装
RUN echo "=== 环境版本 ===" \
    && node --version \
    && npm --version \
    && bun --version \
    && rustc --version \
    && cargo --version \
    && wasm-pack --version \
    && rustup target list --installed | grep wasm32

# 清理缓存
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

WORKDIR /workspace

CMD ["/bin/bash"]
