# order-mq

> Kafka 消费者：监听 payment 服务的状态变更，触发订单状态联动更新

---

## 业务场景

把"支付完成"这件事**异步**通知到订单服务：
- 用户在微信支付完成后，payment-rpc 调用 `updateTradeState` RPC
- 同一调用里，payment-rpc 还会推一条 JSON 消息到 Kafka `payment-update-paystatus-topic`
- **本进程** 订阅这个 topic，**反序列化 → 调 order-rpc 更新订单状态**

> 为什么不用 RPC 直接调？因为这样**解耦**了:
> - payment 只管推消息，不管谁消费
> - order 状态更新失败不影响 payment 主流程
> - 将来多消费者（统计 / 风控 / 推送）不用改 payment 代码

---

## 它做了什么

```
+--------------------+   推 JSON   +----------------------+   拉消息
| payment-rpc        | ─────────► |  Kafka topic          | ◄─────────┐
| KqueuePusher.Push  |            |  payment-update-      |           │
+--------------------+            |  paystatus-topic      |           │
                                  +----------------------+           │
                                          │                          │
                                          │ broker 通知              │
                                          ▼                          │
                                  +----------------------+           │
                                  | order-mq 进程        |           │
                                  | (本进程)              |           │
                                  |                      |           │
                                  | 1. kq.MustNewQueue   |           │
                                  |    (consumer group)  |           │
                                  | 2. Consume(string)   |           │
                                  | 3. json.Unmarshal    |           │
                                  | 4. 调 order-rpc       |           │
                                  |    UpdateTradeState  |           │
                                  +----------------------+           │
                                          │                          │
                                          └──── success/fail ────────┘
                                                 (offset commit)
```

---

## 当前消费的消息

| 文件 | Topic | Group | 消息体 | 触发什么 |
|------|-------|-------|--------|----------|
| [`mqs/kq/paymentUpdateStatus.go`](internal/mqs/kq/paymentUpdateStatus.go) | `payment-update-paystatus-topic` | `payment-update-paystatus-group` | `ThirdPaymentUpdatePayStatusNotifyMessage{OrderSn, PayStatus}` | 调 `order-rpc.UpdateHomestayOrderTradeState` |

消息格式 (来自 `pkg/kqueue/`):

```go
type ThirdPaymentUpdatePayStatusNotifyMessage struct {
    OrderSn   string  // 订单号
    PayStatus int64   // 支付状态 (1=已支付, 2=已退款, ...)
}
```

---

## 关键代码定位

```go
// 入口: order.go
serviceGroup := service.NewServiceGroup()
for _, mq := range listen.Mqs(c) {
    serviceGroup.Add(mq)   // ← 把所有 mq (目前只有 kq) 加进服务组
}
serviceGroup.Start()       // ← 阻塞, 一直消费

// 注册: internal/listen/kqMqs.go
return []service.Service{
    kq.MustNewQueue(c.PaymentUpdateStatusConf, kqMq.NewPaymentUpdateStatusMq(ctx, svcContext)),
}

// 消费: internal/mqs/kq/paymentUpdateStatus.go
func (l *PaymentUpdateStatusMq) Consume(_, val string) error {
    json.Unmarshal([]byte(val), &message)  // 1. 解析
    l.execService(message)                 // 2. 调 order-rpc
}

// execService: 调 order-rpc.UpdateHomestayOrderTradeState
// 副作用 1: order homestay_order.trade_state 改了
// 副作用 2: order-rpc 内部还会 enqueue 一个 asynq 任务 (msg:pay_success:notify_user)
//           → mqueue-job 来消费 + 推送
```

---

## 怎么启动

```bash
# 方式 A: 一键
./scripts/dev-up.sh

# 方式 B: 单独启动
go build -o ./tmp/order-mq ./app/order/cmd/mq
./tmp/order-mq -f ./app/order/cmd/mq/etc/order.yaml
```

启动后**不会**有"started"消息直接打到 stdout（kq 库默认安静），
需要靠日志间接看活跃状态。

---

## 怎么验证

### 验证 1: 这个进程能连上 Kafka

```bash
# 看 log 是否有连接消息 (dev-up.sh v3.9 之后有 log)
tail -n 50 tmp/logs/order-mq.log
# 看到像 "consumer started" "listening" "topic subscribed" 就对了

# 看 Kafka 那边是否认识 consumer group
docker exec kafka /bin/sh -c "
cd /opt/kafka/bin && \
./kafka-consumer-groups.sh --bootstrap-server localhost:9094 --list
"
# 应该看到 "payment-update-paystatus-group"
```

### 验证 2: 推一条消息，看是否真消费

**方式一：从 payment-rpc 真实触发** (需要完整 e2e)

**方式二 (推荐, 排错时用): 手动往 Kafka 灌一条**

```bash
ORDER_SN="HSO20260806_xxx"   # ← 改成你的真实订单号

docker exec kafka /bin/sh -c "
cd /opt/kafka/bin && \
echo '{\"OrderSn\":\"$ORDER_SN\",\"PayStatus\":1}' | \
./kafka-console-producer.sh --bootstrap-server localhost:9094 \
  --topic payment-update-paystatus-topic
"

# 立即查两件事:
# 1) Kafka offset 变化
docker exec kafka /bin/sh -c "
cd /opt/kafka/bin && \
./kafka-run-class.sh kafka.tools.GetOffsetShell \
  --bootstrap-server localhost:9094 --topic payment-update-paystatus-topic
"

# 2) MySQL trade_state 应该被改成对应状态
docker exec mysql mysql -uroot -pPXDN93VRKUm8TeE7 looklook_order \
  -e "SELECT sn, trade_state FROM homestay_order WHERE sn='$ORDER_SN'"
```

### 验证 3: 副作用链条 (完整 demo)

推一条 Kafka → order-mq 消费 → order-rpc 改 trade_state → 触发 mqueue-job 的 D 任务

```bash
# 推 Kafka 消息之后, 还会看到:
docker exec -e REDISCLI_AUTH=G62m50oigInC30sf redis redis-cli \
  ZRANGE 'asynq:{default}:pending' 0 -1
# 应该看到新出现的 msg:pay_success:notify_user:xxx 任务
# → mqueue-job 会立即消费, 输出推送 stub log
```

---

## 怎么调试

### 症状: 进程在但 log 是 0 字节

```bash
# 1. 看 log
ls -la tmp/logs/order-mq.log
cat tmp/logs/order-mq.log

# 2. 进程在不在
ps aux | grep order-mq | grep -v grep

# 3. dev-up.sh v3.9 之后应该能看到 kq 启动消息
#    看不到 = log 被 buffer / 服务没起
```

### 症状: 推消息没反应 (consumer 没动)

```bash
# 1. 查 Brokers 是否对得上 (host 上要 127.0.0.1:9094, 不是 kafka:9092)
grep -A 2 "Brokers:" app/order/cmd/mq/etc/order.yaml

# 2. Kafka topic 存在吗
docker exec kafka /bin/sh -c "
cd /opt/kafka/bin && \
./kafka-topics.sh --list --bootstrap-server localhost:9094
"

# 3. Consumer group 是否注册
docker exec kafka /bin/sh -c "
cd /opt/kafka/bin && \
./kafka-consumer-groups.sh --bootstrap-server localhost:9094 --describe --all-groups
"
```

### 症状: 消费成功但 order 没更新

查 order-rpc 进程是否活着 + network 通不通:

```bash
# 1. order-rpc 在监听?
lsof -i :2001

# 2. order-mq 的 Processors 配对了吗 (yaml 里 Processors: 1)
grep Processors app/order/cmd/mq/etc/order.yaml
```

---

## 跟 Kafka 容器端口特别说明

`docker-compose-env.yml` 里 Kafka 端口:

```
9092:9092   ← 容器内部, 容器-容器之间用
9094:9094   ← 容器外 (host), 外部访问用
```

KAFKA_ADVERTISED_LISTENERS:
```
PLAINTEXT://localhost:9094              ← host 客户端连这个
PLAINTEXT_CONTAINER://kafka:9092        ← docker 网络内连这个
```

> ⚠️ **host 模式跑的本进程** 必须用 `127.0.0.1:9094`，**不是** `kafka:9092`
> (这是 Step 1 踩过的同样坑, v3.12 commit 修了)

---

## 文件结构

```
app/order/cmd/mq/
├── README.md                       ← 本文件
├── order.go                        ← main entry + serviceGroup 编排
├── etc/
│   └── order.yaml                  ← 配置 (Kafka + Prometheus port 4003)
├── pb/
│   └── order.pb.go                 ← (空, kq 不用 proto, 走 JSON)
└── internal/
    ├── config/
    │   └── config.go               ← yaml struct
    ├── svc/
    │   └── serviceContext.go       ← serviceContext
    ├── listen/
    │   ├── listen.go               ← Mqs() 入口 (返回所有 consumer)
    │   └── kqMqs.go                ← kq (kafka) 消费者注册
    └── mqs/
        └── kq/
            └── paymentUpdateStatus.go  ← handler: 解析 + 调 order-rpc
```

---

## 顺手提醒

| 改的东西 | 要重 build | 要重启 |
|---------|-----------|-------|
| Handler 逻辑 | ✅ | ✅ |
| 新增 mq consumer (改 listen.go + mqs/) | ✅ | ✅ |
| 改 yaml (Brokers/Topic/Group) | ❌ | ✅ |
| 改 protobuf | ✅ + 业务侧 | ✅ + 业务侧 |

---

## 相关文档

- [`../../../notes/upgrade-journal/step-06-async-event-deep-dive.md`](../../../notes/upgrade-journal/step-06-async-event-deep-dive.md) §3 异步事件家族, §6 Kafka Brokers fix
- [kq 文档](https://github.com/zeromicro/go-queue/tree/master/kq) —— Kafka wrapper
- [mqueue-job README](../../mqueue/cmd/job/README.md) —— asynq 消费者（兄弟进程）
- [payment-rpc 入口](../../payment/cmd/rpc/payment.go) —— 看 Push 端
