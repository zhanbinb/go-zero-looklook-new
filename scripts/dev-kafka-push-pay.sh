#!/bin/bash
# scripts/dev-kafka-push-pay.sh
# 模拟"支付成功"的 Kafka 消息推送 - 走 payment-rpc 真实 Push 后的链路
#
# 用法 (参数任意一种):
#   ./scripts/dev-kafka-push-pay.sh ORDER_SN=HSO20...
#   ./scripts/dev-kafka-push-pay.sh HSO20...                                  # 纯 SN 也行
#   ./scripts/dev-kafka-push-pay.sh ORDER_SN=HSO20... PAY_STATUS=2            # 改状态 (2=Refund)
#
# 环境变量 (可选, 默认会用):
#   KAFKA_BROKER   - kafka bootstrap-server (默认 localhost:9094)
#   KAFKA_TOPIC    - topic name (默认 payment-update-paystatus-topic)
#
# 推送内容 (跟 payment-rpc 真实推送一致):
#   {"OrderSn":"HSO...","PayStatus":1}
# PayStatus 映射 (来自 order-mq/kq/paymentUpdateStatus.go):
#   1 → trade_state 1 (WaitUse)    我们的 happy path
#   2 → trade_state 3 (Refund)
#   3 → trade_state -1 (Cancel)
#   其他 → 不动 (-99)
set -euo pipefail
cd "$(dirname "$0")/.."

# ---- 1. 解析参数 ----
ORDER_SN=""
PAY_STATUS=1
for arg in "$@"; do
    case "$arg" in
        ORDER_SN=*)  ORDER_SN="${arg#ORDER_SN=}" ;;
        PAY_STATUS=*) PAY_STATUS="${arg#PAY_STATUS=}" ;;
        HSO*|HO*)    ORDER_SN="$arg" ;;  # 兼容裸 SN
        *)            echo "未知参数: $arg"; exit 1 ;;
    esac
done

if [ -z "$ORDER_SN" ]; then
    echo "❌ 必须传 ORDER_SN"
    echo "用法: $0 ORDER_SN=HSO20..."
    echo "    或: $0 HSO20..."
    exit 1
fi

# ---- 2. 默认值 ----
KAFKA_BROKER="${KAFKA_BROKER:-localhost:9094}"
KAFKA_TOPIC="${KAFKA_TOPIC:-payment-update-paystatus-topic}"

# ---- 3. 构造消息体 ----
PAYLOAD="{\"OrderSn\":\"${ORDER_SN}\",\"PayStatus\":${PAY_STATUS}}"

# ---- 4. 打印 header (让人知道要发生什么) ----
echo "=========================================="
echo "🔔 模拟 '支付完成' 推送"
echo "=========================================="
echo "ORDER_SN  = $ORDER_SN"
echo "PAY_STATUS = $PAY_STATUS  (映射到 trade_state 见脚本注释)"
echo "BROKER    = $KAFKA_BROKER"
echo "TOPIC     = $KAFKA_TOPIC"
echo "PAYLOAD   = $PAYLOAD"
echo "=========================================="

# ---- 5. 推 ----
# docker exec 需要 echo $PAYLOAD 转义. 用 stdin heredoc 不行 (会带换行)
# 这里用 printf + 管道
docker exec kafka /bin/sh -c "
cd /opt/kafka/bin && \
printf '%s\n' '${PAYLOAD}' | \
./kafka-console-producer.sh \
  --bootstrap-server ${KAFKA_BROKER} \
  --topic ${KAFKA_TOPIC}" \
  || { echo "❌ Kafka 推送失败"; exit 1; }

# ---- 6. 推送后的 immediate 验证 ----
echo ""
echo "📊 推送后立即查 (expect offset +1):"
docker exec kafka /bin/sh -c "
cd /opt/kafka/bin && \
./kafka-run-class.sh kafka.tools.GetOffsetShell \
  --bootstrap-server ${KAFKA_BROKER} \
  --topic ${KAFKA_TOPIC} 2>/dev/null || \
./kafka-consumer-groups.sh \
  --bootstrap-server ${KAFKA_BROKER} \
  --describe --group payment-update-paystatus-group 2>/dev/null"
echo ""
echo "✅ 推送完成. 等 1-2 秒, 然后跑:"
echo "   ./scripts/dev-mq-trace.sh ORDER_SN=$ORDER_SN   # 看 4 件套"
