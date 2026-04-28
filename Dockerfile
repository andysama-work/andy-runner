# Gitea Act Runner 自定义镜像
# 包含: Bun, Node.js, npm, Rust, wasm-pack, Tauri 依赖

FROM debian:bookworm-slim

LABEL maintainer="andy"
LABEL description="Gitea Runner with Bun, Node.js, Rust, wasm-pack"

ENV DEBIAN_FRONTEND=noninteractive \
    RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    RUSTUP_DIST_SERVER=https://rsproxy.cn \
    RUSTUP_UPDATE_ROOT=https://rsproxy.cn/rustup \
    CARGO_REGISTRIES_CRATES_IO_PROTOCOL=sparse \
    PATH=/usr/local/cargo/bin:/usr/local/bin:$PATH

# 替换为清华源加速
RUN sed -i 's/deb.debian.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list.d/debian.sources || \
    sed -i 's|http://deb.debian.org|https://mirrors.tuna.tsinghua.edu.cn|g' /etc/apt/sources.list

# 合并所有安装步骤减少层数，并在同一层清理缓存
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    git \
    openssh-client \
    sshpass \
    xz-utils \
    build-essential \
    pkg-config \
    libssl-dev \
    unzip \
    libgtk-3-dev \
    libwebkit2gtk-4.1-dev \
    libayatana-appindicator3-dev \
    librsvg2-dev \
    # 安装 Node.js (使用清华镜像)
    && curl -fsSL --retry 5 --retry-all-errors https://mirrors.tuna.tsinghua.edu.cn/nodejs-release/v20.11.0/node-v20.11.0-linux-x64.tar.xz -o /tmp/node.tar.xz \
    && tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 \
    # 安装 Bun (通过 npm + npmmirror)
    && npm config set registry https://registry.npmmirror.com \
    && npm install -g bun@latest \
    && npm config set registry https://registry.npmjs.org \
    # 安装 Rust (minimal profile 减少体积)
    && mkdir -p $CARGO_HOME \
    && curl --proto '=https' --tlsv1.2 -sSf --retry 5 --retry-all-errors https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --profile minimal \
    && printf '[source.crates-io]\nreplace-with = "rsproxy-sparse"\n[source.rsproxy-sparse]\nregistry = "sparse+https://rsproxy.cn/index/"\n[net]\ngit-fetch-with-cli = true\n' > $CARGO_HOME/config.toml \
    && rustup target add wasm32-unknown-unknown \
    # 安装 wasm-pack
    && cargo install wasm-pack --locked \
    # 清理所有缓存
    && rm -rf /tmp/* \
    && rm -rf $CARGO_HOME/registry \
    && rm -rf $CARGO_HOME/git \
    && rustup component remove rust-docs 2>/dev/null || true \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/apt/archives/*

# 验证安装
RUN node --version && npm --version && bun --version && rustc --version && wasm-pack --version

WORKDIR /workspace
CMD ["/bin/bash"]
