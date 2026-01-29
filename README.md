# Gitea Runner 自定义镜像

包含以下环境：
- Node.js 20 LTS
- npm
- Bun
- Rust (stable)
- wasm-pack
- wasm32-unknown-unknown target

## 构建镜像

```bash
cd docker/runner
chmod +x build.sh
./build.sh
```

或手动构建：

```bash
docker build -t gitea-runner-full:latest .
```

## 测试镜像

```bash
docker run -it gitea-runner-full:latest /bin/bash

# 在容器内验证
node --version
npm --version
bun --version
rustc --version
wasm-pack --version
```

## 推送到私有仓库

```bash
# 打标签
docker tag gitea-runner-full:latest 192.168.192.1:5000/gitea-runner-full:latest

# 推送
docker push 192.168.192.1:5000/gitea-runner-full:latest
```

## 配置 Gitea Runner

修改 runner 的 `config.yaml`：

```yaml
runner:
  labels:
    - "full:docker://192.168.192.1:5000/gitea-runner-full:latest"
```

或者如果镜像在本地：

```yaml
runner:
  labels:
    - "full:docker://gitea-runner-full:latest"
```

## 在工作流中使用

```yaml
jobs:
  build:
    runs-on: full  # 使用自定义标签
    steps:
      - name: 检出代码
        uses: actions/checkout@v4
      
      - name: 构建 WASM
        run: |
          wasm-pack build --target web --release
```
