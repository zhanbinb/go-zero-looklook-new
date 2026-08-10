#!/bin/bash
# scripts/dev-apisix-status.sh
# 看 APISIX + Dashboard 端到端状态
set -e
cd "$(dirname "$0")/.."

echo "==== 1) 2 容器状态 ===="
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null | grep -E "apisix" || echo "(APISIX 没启)"

echo ""
echo "==== 2) Admin API 健康 ===="
curl -is http://127.0.0.1:9180/apisix/admin/routes \
    -H "X-API-KEY: edd1c9f034325f303f3f3f3f3f3f3f3f" 2>&1 | head -3

echo ""
echo "==== 3) Dashboard 健康 ===="
curl -is http://127.0.0.1:9000/ 2>&1 | head -3

echo ""
echo "==== 4) 当前 route 列表 (空 = 还没配) ===="
curl -s http://127.0.0.1:9180/apisix/admin/routes \
    -H "X-API-KEY: edd1c9f034325f303f3f3f3f3f3f3f3f" | jq '.total, (.list | map({key: .key, name: .name, uri: .uri}))' 2>/dev/null || \
    echo "(Admin API 没响应)"

echo ""
echo "==== 5) 当前 upstream 列表 ===="
curl -s http://127.0.0.1:9180/apisix/admin/upstreams \
    -H "X-API-KEY: edd1c9f034325f303f3f3f3f3f3f3f3f" | jq '.total, (.nodes | map({host: .host, port: .port}))' 2>/dev/null || \
    echo "(没 upstream)"

echo ""
echo "==== 6) HTTP proxy 端到端 ===="
curl -is http://127.0.0.1:9080/ 2>&1 | head -2
# 预期: 404 No Route (还没配 route)

echo ""
echo "==== 7) 端口一览 ===="
echo "  - Admin API:  http://127.0.0.1:9180"
echo "  - HTTP proxy: http://127.0.0.1:9080"
echo "  - Dashboard:  http://127.0.0.1:9000  (admin/admin)"
