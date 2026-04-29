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

# 保留 Debian 默认源
RUN sed -i 's|https://mirrors.tuna.tsinghua.edu.cn|http://deb.debian.org|g; s|http://mirrors.tuna.tsinghua.edu.cn|http://deb.debian.org|g' /etc/apt/sources.list.d/debian.sources || \
    sed -i 's|https://mirrors.tuna.tsinghua.edu.cn|http://deb.debian.org|g; s|http://mirrors.tuna.tsinghua.edu.cn|http://deb.debian.org|g' /etc/apt/sources.list

# 合并所有安装步骤减少层数，并在同一层清理缓存
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    bash \
    curl \
    wget \
    git \
    openssh-client \
    sshpass \
    xz-utils \
    tzdata \
    build-essential \
    pkg-config \
    libssl-dev \
    unzip \
    clang \
    libgtk-3-dev \
    libwebkit2gtk-4.1-dev \
    libayatana-appindicator3-dev \
    librsvg2-dev \
    mingw-w64 \
    # 安装 Node.js (使用官方源)
    && curl -fsSL --retry 5 --retry-all-errors https://nodejs.org/dist/v20.11.0/node-v20.11.0-linux-x64.tar.xz -o /tmp/node.tar.xz \
    && tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 \
    # 安装 Bun (通过 npm + npmmirror)
    && npm config set registry https://registry.npmmirror.com \
    && npm install -g bun@latest \
    && npm config set registry https://registry.npmjs.org \
    # 安装 Rust (minimal profile 减少体积)
    && mkdir -p $CARGO_HOME \
    && curl --proto '=https' --tlsv1.2 -sSf --retry 5 --retry-all-errors https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --profile minimal \
    && printf '[source.crates-io]\nreplace-with = "rsproxy-sparse"\n[source.rsproxy-sparse]\nregistry = "sparse+https://rsproxy.cn/index/"\n[net]\ngit-fetch-with-cli = true\n[target.x86_64-pc-windows-gnu]\nlinker = "x86_64-w64-mingw32-gcc"\nar = "x86_64-w64-mingw32-gcc-ar"\n' > $CARGO_HOME/config.toml \
    && rustup target add wasm32-unknown-unknown \
    && rustup target add x86_64-unknown-linux-gnu aarch64-unknown-linux-gnu x86_64-apple-darwin aarch64-apple-darwin x86_64-pc-windows-gnu \
    # 安装 Zig (用于 cargo-zigbuild 跨平台编译)
    && curl -fsSL --retry 5 --retry-all-errors https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz -o /tmp/zig.tar.xz \
    && tar -xJf /tmp/zig.tar.xz -C /tmp \
    && mv /tmp/zig-linux-x86_64-0.13.0 /usr/local/zig \
    && ln -s /usr/local/zig/zig /usr/local/bin/zig \
    # 安装 wasm-pack 和 cargo-zigbuild (使用 clang 避免 GCC ICE)
    && CC=clang cargo install wasm-pack --locked \
    && CC=clang cargo install cargo-zigbuild --locked \
    # 清理所有缓存
    && rm -rf /tmp/* \
    && rm -rf $CARGO_HOME/registry \
    && rm -rf $CARGO_HOME/git \
    && (rustup component remove rust-docs 2>/dev/null || true) \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/apt/archives/*

# 下载并安装 Gitea act_runner (v0.5.0)
RUN curl -fsSL --retry 5 --retry-all-errors https://dl.gitea.com/act_runner/0.5.0/act_runner-0.5.0-linux-amd64 -o /usr/local/bin/act_runner \
    && chmod +x /usr/local/bin/act_runner

COPY scripts/run.sh /usr/local/bin/run.sh
RUN chmod +x /usr/local/bin/run.sh \
    && mkdir -p /data

# 验证安装
RUN node --version && npm --version && bun --version && rustc --version && wasm-pack --version && act_runner --version

VOLUME ["/data"]
WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/run.sh"]
