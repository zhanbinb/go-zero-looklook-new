#!/bin/sh
# dashboard-entrypoint.sh
# ★ 关键: 把容器内 127.0.0.1:2379 (manager-api 硬编码默认 etcd 地址) 重定向到
#   host.docker.internal:2379 (宿主机上发布的 etcd)
#   这样不管 manager-api 内部用哪个地址, 都能连上 etcd
set -e

# 1) 装 socat (apline 默认没有)
if ! command -v socat >/dev/null 2>&1; then
  apk add --no-cache socat >/dev/null 2>&1
fi

# 2) 启动 socat 重定向: 127.0.0.1:2379 -> host.docker.internal:2379
socat TCP-LISTEN:2379,bind=127.0.0.1,fork,reuseaddr TCP:host.docker.internal:2379 &

# 3) 启动 manager-api
exec /usr/local/apisix-dashboard/manager-api -p /usr/local/apisix-dashboard -c /usr/local/apisix-dashboard/conf/conf.yaml
