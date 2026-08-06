# mqueue-job

> 异步任务执行器：worker 拉 Redis 队列里的任务，路由到对应 handler

---

## 业务场景

它是"真正干活的"异步进程：
- [scheduler 进程](../scheduler/README.md) cron 到点把任务塞进 Redis
- 业务代码（order-rpc / payment-rpc）调 `asynq.Enqueue` 把任务塞进 Redis
- **本进程** 从 Redis 拉任务，按 task type 路由到对应 handler 执行

> 跟 scheduler 的区别：scheduler 只**生成**任务，本进程**消费**任务。
> 真正的"业务执行"都在这里。

---

## 它做了什么

```
+--------------------+   拉任务     +-------------------------+
| job 进程           | ◄────────── |  Redis asynq queues     |
|                    |              |  - {default}:scheduled  |
| 1. AsynqServer.Run |              |  - {default}:pending    |
| 2. 拉任务           |              |  - {default}:retry      |
| 3. 路由 mux.Handle  |              +-------------------------+
| 4. 调 handler        |                        ▲
| 5. success→complete |                        │
|    failure→retry    |                        │
+--------------------+                        │
        │                                     │
        │ RPC 调                               │
        ▼                                     │
+-------------------------+              生成任务
| order-rpc (2001)        | ◄───────────────┘
|  - update trade_state   |
|  - homestay order detail|
+-------------------------+
```

---

## 当前注册的 handler

3 个，覆盖 3 类 asynq 任务：

| 文件 | Task Type | 分类 | 干啥的 |
|------|-----------|------|--------|
| [`settleRecord.go`](internal/logic/settleRecord.go) | `schedule:settle_record:settle` | **cron** | 商户结算 demo (空实现) |
| [`closeOrder.go`](internal/logic/closeOrder.go) | `defer:homestay_order:close` | **defer** | 15/30 分钟未支付订单自动取消 |
| [`paySuccessNotifyUser.go`](internal/logic/paySuccessNotifyUser.go) | `msg:pay_success:notify_user` | **queue** | 支付成功通知用户 (微信推送) |

`ProcessTask` 返回:
- `nil` → 任务成功，asynq 删任务，移到 processed 计数
- `error` → asynq 任务进入 retry 队列，下次重试

要加新 handler:
1. 在 [`jobtype/`](jobtype/) 加常量
2. 在 [`internal/logic/`](internal/logic/) 加 `xxxHandler.go`，实现 `ProcessTask`
3. 在 [`routes.go`](internal/logic/routes.go) 加一行 `mux.Handle(jobtype.Xxx, NewXxxHandler(...))`

---

## 关键代码定位

```go
// 入口: mqueue.go
svcContext.AsynqServer.Run(mux)  // ← 阻塞, 一直拉任务

// 注册路由: internal/logic/routes.go
mux.Handle(jobtype.DeferCloseHomestayOrder, NewCloseHomestayOrderHandler(l.svcCtx))
mux.Handle(jobtype.MsgPaySuccessNotifyUser, NewPaySuccessNotifyUserHandler(l.svcCtx))
mux.Handle(jobtype.ScheduleSettleRecord, NewSettleRecordHandler(l.svcCtx))

// Handler 示例: internal/logic/closeOrder.go
func (l *CloseHomestayOrderHandler) ProcessTask(ctx, t) error {
    payload := ...
    OrderRpc.UpdateHomestayOrderTradeState(...)  // 调 order-rpc
    return nil  // 成功; 非 nil → asynq 触发重试
}
```

---

## 怎么启动

```bash
# 方式 A: 一键 (跟 11 binary 一起)
./scripts/dev-up.sh

# 方式 B: 单独启动 (排错时用)
go build -o ./tmp/mqueue-job ./app/mqueue/cmd/job
./tmp/mqueue-job -f ./app/mqueue/cmd/job/etc/mqueue.yaml
```

启动后:

```
# 注册到 Redis 的 worker (做"活的证书"):
asynq: pid=NNN INFO: Starting asynq server
asynq: pid=NNN INFO: Registered worker
```

---

## 怎么验证

**1. 看 worker 是否注册成功**:

```bash
docker exec -e REDISCLI_AUTH=G62m50oigInC30sf redis redis-cli KEYS 'asynq:servers:*'
# 应该至少有 1 个 keys: asynq:servers:{hostname}:{pid}:{uuid} = 当前 worker
```

**2. 看 processed 计数是否增长** (今天累计执行):

```bash
docker exec -e REDISCLI_AUTH=G62m50oigInC30sf redis redis-cli \
  SCARD 'asynq:{default}:processed:2026-08-06'
# 数字 > 0 表示今天有任务处理过
```

**3. 触发一笔关单 + 实时观察**:

```bash
# 改源码 CloseOrderTimeMinutes = 1, 重 build, 重启
# 下单 → 等 60s → trade_state 应该从 0 变 -1
```

---

## 怎么调试

**症状: 任务没处理 / handler 没跑**

| 排查点 | 命令 |
|--------|------|
| worker 活着吗? | `ps aux \| grep mqueue-job` |
| worker 注册到 Redis 了吗? | `redis-cli KEYS 'asynq:servers:*'` |
| 任务在队列吗? | `redis-cli ZRANGE 'asynq:{default}:scheduled' 0 -1 WITHSCORES` |
| 任务类型对得上 handler? | 对比 `jobtype.Xxx` 常量 和 routes.go 的 mux.Handle |
| handler 出错了? | grep "task insert queue fail" 在 log 里 |

**症状: handler 跑了但效果没出来**

handler 内部业务失败, 不会写 error log (返回 error 才记)。
这种"沉默成功"模式下:
- 看副作用是否落地（MySQL / Redis / 外部）
- 加 DEBUG log 临时进 process 函数

---

## 文件结构

```
app/mqueue/cmd/job/
├── README.md                       ← 本文件
├── mqueue.go                       ← main entry
├── etc/
│   └── mqueue.yaml                 ← 配置 (Redis addr + Prometheus port 4010)
├── jobtype/
│   ├── jobtype.go                  ← 3 个 task type 常量
│   └── jobpayload.go               ← task payload struct 定义
└── internal/
    ├── config/                     ← yaml 结构 + SetUp + wxMiniConfig
    ├── svc/
    │   ├── serviceContext.go       ← asynq.Server 实例化
    │   └── asynqServer.go          ← asynq.NewServer 配置 (concurrency/queues)
    └── logic/
        ├── routes.go               ← mux 路由表 (★)
        ├── settleRecord.go         ← handler #1
        ├── closeOrder.go           ← handler #2
        └── paySuccessNotifyUser.go ← handler #3
```

---

## 顺手提醒 — 调试改源码注意事项

| 改的东西 | 要不要重 build | 要不要重启 |
|---------|----------------|-----------|
| handler 逻辑 | ✅ | ✅ |
| 新增 handler (改 routes.go) | ✅ | ✅ |
| 改 `jobtype` 常量 (破坏性) | ✅ | ✅ + 重 build 业务侧 |
| 改 yaml 配置 (端口/队列名) | ❌ | ✅ |
| 改 `internal/svc/asynqServer.go` 的 concurrency | ✅ | ✅ |

---

## 相关文档

- [`../../../notes/upgrade-journal/step-06-async-event-deep-dive.md`](../../../notes/upgrade-journal/step-06-async-event-deep-dive.md) §3 异步事件家族
- [scheduler README](../scheduler/README.md) —— 任务生产者
- [order-mq README](../../order/cmd/mq/README.md) —— Kafka 消费者（兄弟进程）
- [asynq 文档](https://github.com/hibiken/asynq) —— `Server`/`ServeMux` API
