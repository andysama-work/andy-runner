#!/bin/bash
# 构建自定义 Runner 镜像

IMAGE_NAME="gitea-runner-full"
IMAGE_TAG="latest"

echo "🔨 构建镜像: ${IMAGE_NAME}:${IMAGE_TAG}"

docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

if [ $? -eq 0 ]; then
    echo "✅ 构建成功!"
    echo ""
    echo "📦 镜像信息:"
    docker images ${IMAGE_NAME}
    echo ""
    echo "🚀 使用方法:"
    echo "  1. 测试镜像: docker run -it ${IMAGE_NAME}:${IMAGE_TAG} /bin/bash"
    echo "  2. 推送到私有仓库: docker tag ${IMAGE_NAME}:${IMAGE_TAG} 192.168.192.1:5000/${IMAGE_NAME}:${IMAGE_TAG}"
    echo "                     docker push 192.168.192.1:5000/${IMAGE_NAME}:${IMAGE_TAG}"
else
    echo "❌ 构建失败"
    exit 1
fi
