#!/bin/bash
# scripts/dev-mq-trace.sh
# 一笔订单跨所有异步事件的'全景体检' 脚本
# 用法: ./scripts/dev-mq-trace.sh ORDER_SN=HSO20...
# 或:    ./scripts/dev-mq-trace.sh HSO20...
#
# 输出 7 块检查:
#   1. MySQL trade_state (ground truth)
#   2. Kafka topic offset + consumer group lag
#   3. Redis asynq:* keys 全景
#   4. Redis D task (msg:pay_success:notify_user) 状态
#   5. Redis C task (defer:homestay_order:close) 状态
#   6. order-mq.log 最近 20 行
#   7. mqueue-job.log 最近 20 行
set -euo pipefail
cd "$(dirname "$0")/.."

# ---- 1. 参数 ----
ORDER_SN=""
for arg in "$@"; do
    case "$arg" in
        ORDER_SN=*)  ORDER_SN="${arg#ORDER_SN=}" ;;
        HSO*|HO*)    ORDER_SN="$arg" ;;
        *)            echo "未知参数: $arg"; exit 1 ;;
    esac
done

if [ -z "$ORDER_SN" ]; then
    echo "❌ 必须传 ORDER_SN"
    echo "用法: $0 ORDER_SN=HSO20..."
    echo "    或: $0 HSO20..."
    echo ""
    echo "顺手提示: 用 ./scripts/dev-kafka-push-pay.sh ORDER_SN=HSO... 来推送 Kafka"
    exit 1
fi

# 环境变量
KAFKA_BROKER="${KAFKA_BROKER:-localhost:9094}"
KAFKA_TOPIC="${KAFKA_TOPIC:-payment-update-paystatus-topic}"
REDIS_AUTH="${REDIS_AUTH:-G62m50oigInC30sf}"
MYSQL_PASS="${MYSQL_PASS:-PXDN93VRKUm8TeE7}"

REDIS="docker exec -e REDISCLI_AUTH=$REDIS_AUTH redis redis-cli"
KAFKA_SH="docker exec kafka /bin/sh -c \"cd /opt/kafka/bin &&"

echo "=========================================="
echo "🔍 M2 事件 trace for $ORDER_SN"
echo "=========================================="

# ---- 2. MySQL trade_state (最权威 ground truth) ----
echo ""
echo "▸ MySQL: homestay_order.trade_state"
docker exec mysql mysql -uroot -p"$MYSQL_PASS" looklook_order \
  -e "SELECT sn, user_id, trade_state, order_total_price, create_time
      FROM homestay_order WHERE sn='$ORDER_SN'\G" 2>&1 | grep -v "Warning\|mysql:"

# ---- 3. Kafka 消费组状态 ----
echo ""
echo "▸ Kafka topic: $KAFKA_TOPIC"
docker exec kafka /bin/sh -c "
cd /opt/kafka/bin && \
./kafka-consumer-groups.sh \
  --bootstrap-server $KAFKA_BROKER \
  --describe --group payment-update-paystatus-group 2>&1 || echo '(consumer group 还没建立)'" \
  | head -10

# ---- 4. Redis asynq:* 全景 ----
echo ""
echo "▸ Redis: 所有 asynq:* keys"
$REDIS KEYS 'asynq:*' | sort | head -30

# ---- 5. Redis D 任务 (msg:pay_success) ----
echo ""
echo "▸ Redis: D 任务 (msg:pay_success:notify_user) 状态"
D_KEYS=$($REDIS KEYS 'asynq:{default}:t:*' | head -10)
if [ -z "$D_KEYS" ]; then
    echo "  (无 active task)"
else
    echo "  Active task hashes (最多 10 个):"
    for k in $D_KEYS; do
        # 提取 Type 字段 (asynq 编码在 msg 字段里)
        TYPE=$($REDIS HGET "$k" 'state' 2>/dev/null || echo "?")
        # msg 字段是 asynq 编码的二进制, 用 head -c (按字节) + tr 去掉非 printable
        TASK_TYPE=$($REDIS HGET "$k" 'msg' 2>/dev/null | head -c 60 | tr -cd '[:print:][:space:]' | head -c 50)
        echo "    $k  state=$TYPE  msg[:50]=$TASK_TYPE..."
    done
fi

# ---- 6. Redis C 任务 (defer:close) ----
echo ""
echo "▸ Redis: defer 关单任务 (scheduled ZSET)"
$REDIS ZRANGE 'asynq:{default}:scheduled' 0 -1 WITHSCORES | grep -v "Warning"

# ---- 7. order-mq.log 最近 ----
echo ""
echo "▸ order-mq.log 最近 20 行 (order-mq 的消费痕迹)"
if [ -f tmp/logs/order-mq.log ]; then
    tail -n 20 tmp/logs/order-mq.log
else
    echo "  (log 文件不存在 - 服务可能没起)"
fi

# ---- 8. mqueue-job.log 最近 ----
echo ""
echo "▸ mqueue-job.log 最近 20 行 (D 处理痕迹)"
if [ -f tmp/logs/mqueue-job.log ]; then
    tail -n 20 tmp/logs/mqueue-job.log
else
    echo "  (log 文件不存在)"
fi

echo ""
echo "=========================================="
echo "✅ Trace 完成"
echo "=========================================="
