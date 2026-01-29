# Gitea Act Runner 自定义镜像
# 包含: Bun, Node.js, npm, Rust, wasm-pack, Tauri 依赖

FROM debian:bookworm-slim

LABEL maintainer="andy"
LABEL description="Gitea Runner with Bun, Node.js, Rust, wasm-pack"

ENV DEBIAN_FRONTEND=noninteractive \
    RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:/usr/local/bin:$PATH

# 合并所有安装步骤减少层数，并在同一层清理缓存
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
    libgtk-3-dev \
    libwebkit2gtk-4.1-dev \
    libayatana-appindicator3-dev \
    librsvg2-dev \
    # 安装 Node.js
    && curl -fsSL https://nodejs.org/dist/v20.11.0/node-v20.11.0-linux-x64.tar.xz | tar -xJ -C /usr/local --strip-components=1 \
    # 安装 Bun
    && curl -fsSL https://github.com/oven-sh/bun/releases/download/bun-v1.1.0/bun-linux-x64.zip -o /tmp/bun.zip \
    && unzip /tmp/bun.zip -d /tmp \
    && mv /tmp/bun-linux-x64/bun /usr/local/bin/ \
    && chmod +x /usr/local/bin/bun \
    # 安装 Rust (minimal profile 减少体积)
    && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --profile minimal \
    && rustup target add wasm32-unknown-unknown \
    # 安装 wasm-pack
    && cargo install wasm-pack \
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
