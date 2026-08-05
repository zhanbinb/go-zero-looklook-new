#!/bin/bash
# scripts/dev-down.sh
# 停掉所有 looklook dev 服务进程
# 按服务名清理, 不管二进制在哪个目录 (tmp/ tmp/services/ /tmp/ data/server/ 都能清)
cd "$(dirname "$0")/.."

for name in \
  usercenter-rpc usercenter-api \
  travel-rpc travel-api \
  payment-rpc payment-api \
  order-rpc order-api order-mq \
  mqueue-scheduler mqueue-job; do
  pkill -f "$name" 2>/dev/null
done

# 兜底: 精确匹配本项目 tmp 路径 (覆盖绝对路径/相对路径启动的进程)
pkill -f 'go-zero-looklook-new/tmp/' 2>/dev/null

echo "[dev-down] done (killed leftover dev services if any)"
