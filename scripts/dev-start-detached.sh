#!/bin/bash
# scripts/dev-start-detached.sh
# macOS 兼容: 不依赖 setsid, 用 nohup + disown 启动 11 个 dev 服务
# 跟 dev-up.sh 区别: dev-up.sh 用 trap EXIT 清理, 脚本退出服务被杀;
#                    本脚本 detached, 服务进程独立运行

set -e
cd "$(dirname "$0")/.."
mkdir -p tmp/logs

SERVICES=(
  "usercenter-rpc:./app/usercenter/cmd/rpc/etc/usercenter.yaml"
  "usercenter-api:./app/usercenter/cmd/api/etc/usercenter.yaml"
  "travel-rpc:./app/travel/cmd/rpc/etc/travel.yaml"
  "travel-api:./app/travel/cmd/api/etc/travel.yaml"
  "payment-rpc:./app/payment/cmd/rpc/etc/payment.yaml"
  "payment-api:./app/payment/cmd/api/etc/payment.yaml"
  "order-rpc:./app/order/cmd/rpc/etc/order.yaml"
  "order-api:./app/order/cmd/api/etc/order.yaml"
  "order-mq:./app/order/cmd/mq/etc/order.yaml"
  "mqueue-scheduler:./app/mqueue/cmd/scheduler/etc/mqueue.yaml"
  "mqueue-job:./app/mqueue/cmd/job/etc/mqueue.yaml"
)

for s in "${SERVICES[@]}"; do
  name="${s%%:*}"; cfg="${s#*:}"
  if [ ! -x "./tmp/$name" ]; then
    echo "  ❌ $name binary not found, 先跑 ./scripts/dev-build.sh"
    exit 1
  fi
  nohup "./tmp/$name" -f "$cfg" > "tmp/logs/$name.log" 2>&1 &
  echo "  ✅ $name pid=$!"
done
echo ""
echo "✅ 11 个服务已 detached 启动"
echo "日志: tmp/logs/<service>.log"
echo "查看进程: ps aux | grep tmp/"
echo "停止: ./scripts/dev-down.sh"
