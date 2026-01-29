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
    BUN_INSTALL=/root/.bun \
    RUSTUP_DIST_SERVER=https://rsproxy.cn \
    RUSTUP_UPDATE_ROOT=https://rsproxy.cn/rustup

# 配置 apt 使用阿里云镜像
RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources

# 安装基础依赖
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
    && rm -rf /var/lib/apt/lists/*

# 安装 Node.js (使用 npmmirror)
RUN curl -fsSL https://registry.npmmirror.com/-/binary/node/v20.11.0/node-v20.11.0-linux-x64.tar.xz | tar -xJ -C /usr/local --strip-components=1 \
    && npm config set registry https://registry.npmmirror.com

# 安装 Bun (使用 npmmirror)
RUN curl -fsSL https://registry.npmmirror.com/-/binary/bun/bun-v1.1.0/bun-linux-x64.zip -o bun.zip \
    && unzip bun.zip \
    && mv bun-linux-x64/bun /usr/local/bin/ \
    && chmod +x /usr/local/bin/bun \
    && rm -rf bun.zip bun-linux-x64

# 安装 Rust (使用 rsproxy.cn 镜像)
RUN curl --proto '=https' --tlsv1.2 -sSf https://rsproxy.cn/rustup-init.sh | sh -s -- -y --default-toolchain stable \
    && rustup target add wasm32-unknown-unknown

# 配置 Cargo 使用国内镜像
RUN mkdir -p $CARGO_HOME && echo '[source.crates-io]\n\
replace-with = "rsproxy-sparse"\n\
[source.rsproxy]\n\
registry = "https://rsproxy.cn/crates.io-index"\n\
[source.rsproxy-sparse]\n\
registry = "sparse+https://rsproxy.cn/index/"\n\
[registries.rsproxy]\n\
index = "https://rsproxy.cn/crates.io-index"\n\
[net]\n\
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
