#!/bin/bash
# scripts/dev-apisix-down.sh
# 停掉 APISIX (etcd 不停, 那是 host 上原有的, 别人可能在用)
# 用法: ./scripts/dev-apisix-down.sh
set -e
cd "$(dirname "$0")/.."

cd deploy/apisix
docker-compose down
echo "✅ APISIX 已停 (host etcd 保留, 因为不是我们起的)"
