#!/bin/bash
# scripts/start-usercenter.sh
# Used by air.usercenter.toml's full_bin.
# Starts usercenter-rpc + usercenter-api, kills both on signal.
#
# Why a script: air can only run ONE process via full_bin.
# We need both rpc + api, so a script orchestrates them.

set -e

cleanup() {
  if [ -n "$RPC_PID" ] && kill -0 $RPC_PID 2>/dev/null; then
    kill $RPC_PID 2>/dev/null
  fi
  if [ -n "$API_PID" ] && kill -0 $API_PID 2>/dev/null; then
    kill $API_PID 2>/dev/null
  fi
  # 等待两个子进程都退出
  wait 2>/dev/null
}
trap cleanup EXIT INT TERM

# 启动 rpc
./tmp/usercenter-rpc \
  -f ./app/usercenter/cmd/rpc/etc/usercenter.yaml &
RPC_PID=$!
echo "[start-usercenter.sh] usercenter-rpc PID: $RPC_PID, port 2004"

# 启动 api
./tmp/usercenter-api \
  -f ./app/usercenter/cmd/api/etc/usercenter.yaml &
API_PID=$!
echo "[start-usercenter.sh] usercenter-api PID: $API_PID, port 1004"

# 等待任意一个退出
wait -n

# 任一进程退出, 触发 trap cleanup
echo "[start-usercenter.sh] one process exited, cleaning up..."
