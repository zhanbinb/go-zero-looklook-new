#!/bin/bash
# scripts/dev-nginx-reload.sh
# 重载我们 docker 里的 nginx-gateway (改 conf 后用这个)
# 用法: ./scripts/dev-nginx-reload.sh
set -e
cd "$(dirname "$0")/.."

CONTAINER=nginx-gateway
CONF_PATH=deploy/nginx/conf.d/looklook-gateway.conf

echo "==== 1. 测 conf 语法 ===="
docker exec $CONTAINER nginx -t 2>&1

echo ""
echo "==== 2. 重新读取 conf (热加载, 不重启) ===="
docker exec $CONTAINER nginx -s reload 2>&1

echo ""
echo "==== 3. 验证 ===="
sleep 1
docker exec $CONTAINER ps aux 2>&1 | grep "nginx: master" | head -1

echo ""
echo "✅ nginx reload done. 看完整 log: docker logs --tail 20 $CONTAINER"
