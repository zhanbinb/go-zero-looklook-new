#!/bin/bash
# scripts/dev-up.sh
# 后台启动全部 11 个服务, 退出时全部清理 (对标 modd.conf 的 daemon)
# 由 .air.toml 的 [build].full_bin 调用
#
# 要点:
#   1. 启动前先杀掉上一轮残留进程 (air 强杀脚本时可能遗留孤儿进程)
#   2. 用 ps 状态 + wait 轮询代替 wait -n (macOS 自带 bash 3.2 不支持 wait -n)
#   3. 收到 INT/TERM/EXIT 时 kill 所有子进程
set -e
cd "$(dirname "$0")/.."

# 1) 清理上一轮残留, 防止端口被占
./scripts/dev-down.sh >/dev/null 2>&1 || true

# 2) 服务清单: "名字:binary:配置文件" (和 modd.conf 完全一致, 共 11 个)
SERVICES=(
  "usercenter-rpc:./tmp/usercenter-rpc:./app/usercenter/cmd/rpc/etc/usercenter.yaml"
  "usercenter-api:./tmp/usercenter-api:./app/usercenter/cmd/api/etc/usercenter.yaml"
  "travel-rpc:./tmp/travel-rpc:./app/travel/cmd/rpc/etc/travel.yaml"
  "travel-api:./tmp/travel-api:./app/travel/cmd/api/etc/travel.yaml"
  "payment-rpc:./tmp/payment-rpc:./app/payment/cmd/rpc/etc/payment.yaml"
  "payment-api:./tmp/payment-api:./app/payment/cmd/api/etc/payment.yaml"
  "order-rpc:./tmp/order-rpc:./app/order/cmd/rpc/etc/order.yaml"
  "order-api:./tmp/order-api:./app/order/cmd/api/etc/order.yaml"
  "order-mq:./tmp/order-mq:./app/order/cmd/mq/etc/order.yaml"
  "mqueue-scheduler:./tmp/mqueue-scheduler:./app/mqueue/cmd/scheduler/etc/mqueue.yaml"
  "mqueue-job:./tmp/mqueue-job:./app/mqueue/cmd/job/etc/mqueue.yaml"
)

NAMES=()
PIDS=()
DEAD=()

start_one() {
  local entry="$1" rest name bin cfg
  name="${entry%%:*}"
  rest="${entry#*:}"
  bin="${rest%%:*}"
  cfg="${rest#*:}"
  if [ ! -x "$bin" ]; then
    echo "[dev-up] ERROR: $bin not found, 先构建 (air 会自动 build, 或手动 ./scripts/dev-build.sh)"
    exit 1
  fi
  "$bin" -f "$cfg" &
  NAMES+=("$name")
  PIDS+=("$!")
  echo "[dev-up] started $name (pid $!)"
}

cleanup() {
  echo "[dev-up] stopping services..."
  for pid in "${PIDS[@]}"; do
    kill "$pid" 2>/dev/null || true
  done
  ./scripts/dev-down.sh >/dev/null 2>&1 || true
  wait 2>/dev/null || true
}
trap cleanup EXIT INT TERM

for entry in "${SERVICES[@]}"; do
  start_one "$entry"
done

echo "[dev-up] all services started. waiting ... (rebuild / Ctrl+C 时自动清理)"

# 3) poll loop: 只要有服务活着就继续等; 服务退出时告警并收割
while :; do
  sleep 2
  alive=0
  for i in "${!PIDS[@]}"; do
    stat=$(ps -p "${PIDS[$i]}" -o stat= 2>/dev/null || true)
    if [ -n "$stat" ] && [[ "$stat" != *Z* ]]; then
      alive=$((alive + 1))
    elif [ -z "${DEAD[$i]}" ]; then
      DEAD[$i]=1
      wait "${PIDS[$i]}" 2>/dev/null || true   # 收割, 防止变僵尸
      echo "[dev-up] WARN: ${NAMES[$i]} (pid ${PIDS[$i]}) has exited"
    fi
  done
  if [ "$alive" -eq 0 ]; then
    echo "[dev-up] all services exited"
    exit 1
  fi
done
