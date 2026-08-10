#!/bin/bash
# scripts/dev-apisix-up.sh
# 启动 APISIX + Dashboard (复用 host 上已有的 etcd)
# 用法: ./scripts/dev-apisix-up.sh
set -e
cd "$(dirname "$0")/.."

cd deploy/apisix
docker-compose up -d

echo ""
echo "==== 验证 host 上 etcd 在 2379 (前置条件) ===="
if ! docker ps --format '{{.Names}} {{.Ports}}' | grep -q ":2379"; then
    echo "❌ host 上没 etcd 在 2379 跑"
    echo "   跑这个起一个: docker run -d -p 2379:2379 -p 2380:2380 --name etcd quay.io/coreos/etcd:v3.5.21 etcd --listen-client-urls http://0.0.0.0:2379 --advertise-client-urls http://0.0.0.0:2379"
    exit 1
fi
echo "✅ etcd 已在 2379 跑"

echo ""
echo "==== 等待 APISIX ready (15 秒) ===="
for i in {1..30}; do
    if curl -sf http://127.0.0.1:9180/apisix/admin/routes \
        -H "X-API-KEY: edd1c9f034325f303f3f3f3f3f3f3f3f" >/dev/null 2>&1; then
        echo "✅ APISIX Admin API ready"
        break
    fi
    sleep 0.5
done

echo ""
echo "==== 3 容器状态 (APISIX + Dashboard + 你原 etcd) ===="
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' \
    | grep -E "apisix|etcd"

echo ""
echo "==== 端到端验证 ===="
echo "Admin API:  curl -i http://127.0.0.1:9180/apisix/admin/routes -H 'X-API-KEY: edd1c9f034325f303f3f3f3f3f3f3f3f'"
echo "HTTP proxy: curl -i http://127.0.0.1:9080/  (预期 404 No Route)"
echo "Dashboard:  http://127.0.0.1:9000  (admin/admin, 等 dashboard 容器 ready)"
