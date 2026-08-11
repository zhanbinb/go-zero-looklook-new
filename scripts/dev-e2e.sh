#!/bin/bash
# scripts/dev-e2e.sh
# M3/M4 回归基线: login -> browse -> create order -> pay push -> state sync
#                    -> (optional) timeout close
#
# 用法:
#   ./scripts/dev-e2e.sh                         # happy path 回归
#   E2E_CLOSE_VERIFY=1 ./scripts/dev-e2e.sh      # 额外等待超时关单 (需要 CloseOrderTimeMinutes=1 的 build)
#
# 环境变量 (可选):
#   API_BASE=127.0.0.1   MOBILE=18721432599   PASSWORD=test123456   HOMESTAY_ID=1
set -euo pipefail
cd "$(dirname "$0")/.."

API_BASE="${API_BASE:-127.0.0.1}"
MOBILE="${MOBILE:-18721432599}"
PASSWORD="${PASSWORD:-test123456}"
HOMESTAY_ID="${HOMESTAY_ID:-1}"
CLOSE_VERIFY="${E2E_CLOSE_VERIFY:-0}"
MYSQL_PASS="${MYSQL_PASS:-PXDN93VRKUm8TeE7}"
REDIS_AUTH="${REDIS_AUTH:-G62m50oigInC30sf}"

PASS=0
FAIL=0

ok()   { echo "[PASS] $1"; PASS=$((PASS + 1)); }
bad()  { echo "[FAIL] $1"; FAIL=$((FAIL + 1)); }
skip() { echo "[SKIP] $1"; }

abort_if_failed() {
  if [ "$FAIL" -gt 0 ]; then
    echo
    echo "e2e FAIL: $FAIL failed, $PASS passed"
    exit 1
  fi
}

mysql_state() {
  docker exec mysql mysql -uroot -p"$MYSQL_PASS" looklook_order -N \
    -e "SELECT trade_state FROM homestay_order WHERE sn='$1' LIMIT 1" 2>/dev/null \
    | grep -v Warning | head -1 || true
}

find_defer_task() {
  local sn="$1" id msg ids
  ids=$(docker exec -e REDISCLI_AUTH="$REDIS_AUTH" redis redis-cli \
    ZRANGE 'asynq:{default}:scheduled' 0 -1 2>/dev/null | grep -v Warning || true)
  for id in $ids; do
    msg=$(docker exec -e REDISCLI_AUTH="$REDIS_AUTH" redis redis-cli \
      HGET "asynq:{default}:t:$id" msg 2>/dev/null || true)
    if echo "$msg" | grep -a -q 'defer:homestay_order:close' \
      && echo "$msg" | grep -a -q "$sn"; then
      echo "$id"
      return 0
    fi
  done
  return 1
}

future_epoch() {
  local days="$1"
  if date -v+"$days"d +%s >/dev/null 2>&1; then
    date -v+"$days"d +%s
  else
    date -d "+$days days" +%s
  fi
}

create_order() {
  local token="$1" remark="$2" start end resp
  start=$(future_epoch 10)
  end=$(future_epoch 12)
  resp=$(curl -s -X POST "http://$API_BASE:1001/order/v1/homestayOrder/createHomestayOrder" \
    -H "Authorization: Bearer $token" -H 'Content-Type: application/json' \
    -d "{\"homestayId\":$HOMESTAY_ID,\"isFood\":false,\"liveStartTime\":$start,\
         \"liveEndTime\":$end,\"livePeopleNum\":2,\"remark\":\"$remark\"}")
  echo "$resp" | jq -r '.data.orderSn // empty'
}

echo "=========================================="
echo "M3/M4 e2e regression"
echo "=========================================="

# ---- 0. preflight ----
echo "== 0. preflight =="
command -v jq >/dev/null 2>&1 || bad "jq not found"
for p in 1001 1003 1004 2001 2004; do
  if ! lsof -nP -iTCP:"$p" -sTCP:LISTEN >/dev/null 2>&1; then
    bad "port $p not listening"
  fi
done
if ! docker exec kafka true 2>/dev/null; then
  bad "kafka container unreachable"
fi
if ! docker exec mysql mysql --version >/dev/null 2>&1; then
  bad "mysql container unreachable"
fi
if ! docker exec -e REDISCLI_AUTH="$REDIS_AUTH" redis redis-cli ping 2>/dev/null | grep -q PONG; then
  bad "redis container unreachable"
fi
if [ "$FAIL" -eq 0 ]; then
  ok "preflight (ports + docker + jq)"
fi
abort_if_failed

# ---- 1. login ----
echo "== 1. login =="
LOGIN=$(curl -s -X POST "http://$API_BASE:1004/usercenter/v1/user/login" \
  -H 'Content-Type: application/json' \
  -d "{\"mobile\":\"$MOBILE\",\"password\":\"$PASSWORD\"}")
TOKEN=$(echo "$LOGIN" | jq -r '.data.accessToken // empty')
if [ -n "$TOKEN" ]; then
  ok "login got token (${#TOKEN} chars)"
else
  bad "login failed: $(echo "$LOGIN" | head -c 200)"
fi
abort_if_failed

# ---- 2. browse ----
echo "== 2. browse homestay =="
LIST=$(curl -s -X POST "http://$API_BASE:1003/travel/v1/homestay/homestayList" \
  -H 'Content-Type: application/json' -d '{"page":1,"pageSize":5}')
COUNT=$(echo "$LIST" | jq -r '.data.list | length' 2>/dev/null || echo 0)
if [ "${COUNT:-0}" -ge 1 ]; then
  ok "homestayList returned $COUNT items"
else
  bad "homestayList empty: $(echo "$LIST" | head -c 200)"
fi
abort_if_failed

# ---- 3. create order ----
echo "== 3. create order =="
REMARK="e2e_$(date +%s)"
ORDER_SN=$(create_order "$TOKEN" "$REMARK")
if [ -n "$ORDER_SN" ]; then
  ok "order created: $ORDER_SN"
else
  bad "createHomestayOrder returned no orderSn"
fi
abort_if_failed

# ---- 4. initial state = 0 ----
echo "== 4. mysql initial trade_state =="
STATE=$(mysql_state "$ORDER_SN")
if [ "$STATE" = "0" ]; then
  ok "trade_state=0 (WaitPay) right after create"
else
  bad "expected trade_state=0, got '${STATE}'"
fi
abort_if_failed

# ---- 5. defer close task armed ----
echo "== 5. defer close task =="
TASK_ID=$(find_defer_task "$ORDER_SN" || true)
if [ -n "$TASK_ID" ]; then
  SCORE=$(docker exec -e REDISCLI_AUTH="$REDIS_AUTH" redis redis-cli \
    ZSCORE 'asynq:{default}:scheduled' "$TASK_ID" 2>/dev/null | grep -v Warning || true)
  NOW=$(date +%s)
  ok "defer:homestay_order:close scheduled for $ORDER_SN"
  echo "      fire in ~$((SCORE - NOW))s"
else
  bad "defer task not found for $ORDER_SN"
fi
abort_if_failed

# ---- 6. pay push via kafka ----
echo "== 6. simulate payment (kafka) =="
PUSH_LOG=$(./scripts/dev-kafka-push-pay.sh "ORDER_SN=$ORDER_SN" "PAY_STATUS=1" 2>&1 || true)
if echo "$PUSH_LOG" | grep -q "推送完成"; then
  ok "kafka pay push sent: {\"OrderSn\":\"$ORDER_SN\",\"PayStatus\":1}"
else
  bad "kafka push failed: $(echo "$PUSH_LOG" | tail -3 | head -c 200)"
fi
abort_if_failed

# ---- 7. wait trade_state 0 -> 1 ----
echo "== 7. wait trade_state sync =="
STATE=""
for _ in $(seq 1 15); do
  STATE=$(mysql_state "$ORDER_SN")
  if [ "$STATE" = "1" ]; then
    break
  fi
  sleep 1
done
if [ "$STATE" = "1" ]; then
  ok "trade_state 0 -> 1 (order-mq consume + order-rpc update)"
else
  bad "trade_state did not become 1, got '${STATE}'"
fi
abort_if_failed

# ---- 8. optional timeout close ----
echo "== 8. timeout close =="
if [ "$CLOSE_VERIFY" = "1" ]; then
  CLOSE_SN=$(create_order "$TOKEN" "e2e_close_$(date +%s)")
  if [ -z "$CLOSE_SN" ]; then
    bad "failed to create unpaid order for close test"
    abort_if_failed
  fi
  CLOSE_TASK=$(find_defer_task "$CLOSE_SN" || true)
  if [ -z "$CLOSE_TASK" ]; then
    bad "defer task not found for $CLOSE_SN"
    abort_if_failed
  fi
  SCORE=$(docker exec -e REDISCLI_AUTH="$REDIS_AUTH" redis redis-cli \
    ZSCORE 'asynq:{default}:scheduled' "$CLOSE_TASK" 2>/dev/null | grep -v Warning || true)
  NOW=$(date +%s)
  WAIT=$((SCORE - NOW + 15))
  if [ "$WAIT" -gt 150 ]; then
    skip "close task fires in ~$((WAIT - 15))s; need CloseOrderTimeMinutes=1 build to wait"
  else
    echo "      waiting ${WAIT}s for close task..."
    sleep "$WAIT"
    STATE=$(mysql_state "$CLOSE_SN")
    if [ "$STATE" = "-1" ]; then
      ok "timeout close: trade_state 0 -> -1 for $CLOSE_SN"
    else
      bad "expected trade_state=-1 after close, got '${STATE}'"
    fi
  fi
else
  skip "timeout close (set E2E_CLOSE_VERIFY=1; default CloseOrderTimeMinutes=30 不等待)"
fi

echo
echo "=========================================="
echo "e2e result: PASS=$PASS FAIL=$FAIL"
echo "order: $ORDER_SN"
echo "=========================================="
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
