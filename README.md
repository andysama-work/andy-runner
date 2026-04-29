# Gitea Runner 自定义镜像

这是一个集成官方 `act_runner` 启动逻辑的 Gitea Actions Runner 镜像，包含前端、Rust、WASM 和 Tauri 构建环境。

## 内置环境

- Node.js 20 LTS
- npm
- Bun
- Rust stable
- wasm-pack
- cargo-zigbuild
- Zig
- Tauri Linux 依赖
- MinGW-w64
- Gitea `act_runner`

## 构建镜像

```bash
chmod +x build.sh
./build.sh
```

或手动构建：

```bash
docker build -t gitea-runner-full:latest .
```

## 测试镜像

镜像默认入口是 `scripts/run.sh`，传入命令时会直接执行该命令，方便进入容器调试：

```bash
docker run --rm -it gitea-runner-full:latest /bin/bash
```

在容器内验证：

```bash
node --version
npm --version
bun --version
rustc --version
wasm-pack --version
act_runner --version
```

## 启动 Runner

Runner 首次启动时会在 `/data` 下自动注册并生成 `.runner` 文件，后续启动会复用该文件。

```bash
docker run -d \
  --name gitea-runner-full \
  -e GITEA_INSTANCE_URL=https://gitea.example.com \
  -e GITEA_RUNNER_REGISTRATION_TOKEN=<token> \
  -e GITEA_RUNNER_NAME=gitea-runner-full \
  -e GITEA_RUNNER_LABELS=full:docker://gitea-runner-full:latest \
  -v $(pwd)/config.example.yaml:/config.yaml:ro \
  -v $(pwd)/data:/data \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e CONFIG_FILE=/config.yaml \
  gitea-runner-full:latest
```

也可以使用 Docker Compose：

```bash
export GITEA_INSTANCE_URL=https://gitea.example.com
export GITEA_RUNNER_REGISTRATION_TOKEN=<token>
docker compose up -d
```

## 环境变量

| 变量名 | 必需 | 说明 |
| --- | --- | --- |
| `GITEA_INSTANCE_URL` | 首次注册必需 | Gitea 实例地址，不要使用 `localhost` 或 `127.0.0.1` |
| `GITEA_RUNNER_REGISTRATION_TOKEN` | 首次注册必需 | Runner 注册 token |
| `GITEA_RUNNER_REGISTRATION_TOKEN_FILE` | 否 | 从文件读取 token，适合 Docker Secret |
| `GITEA_RUNNER_NAME` | 否 | Runner 名称，默认使用容器 hostname |
| `GITEA_RUNNER_LABELS` | 否 | Runner 标签 |
| `CONFIG_FILE` | 否 | 配置文件路径，例如 `/config.yaml` |
| `RUNNER_STATE_FILE` | 否 | 注册状态文件，默认 `.runner` |
| `GITEA_MAX_REG_ATTEMPTS` | 否 | 注册重试次数，默认 `10` |
| `GITEA_RUNNER_EPHEMERAL` | 否 | 设置后注册为临时 runner |
| `GITEA_RUNNER_ONCE` | 否 | 设置后只执行一个任务 |

## 配置标签

默认示例配置在 `config.example.yaml` 中：

```yaml
runner:
  labels:
    - "full:docker://gitea-runner-full:latest"
```

如果镜像推送到私有仓库，标签可以改为：

```yaml
runner:
  labels:
    - "full:docker://192.168.192.1:5000/gitea-runner-full:latest"
```

## 推送到私有仓库

```bash
docker tag gitea-runner-full:latest 192.168.192.1:5000/gitea-runner-full:latest
docker push 192.168.192.1:5000/gitea-runner-full:latest
```

## 在工作流中使用

```yaml
jobs:
  build:
    runs-on: full
    steps:
      - name: 检出代码
        uses: actions/checkout@v4

      - name: 构建 WASM
        run: |
          wasm-pack build --target web --release
```
