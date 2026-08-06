# mqueue (异步任务子系统)

> 集中管理所有 "**延迟执行 / 定时执行 / 异步广播**" 的任务
> 跟具体业务（订单/支付/民宿）解耦，只关心 **"什么时候跑、跑什么"**

---

## 这里有什么

```
app/mqueue/
├── README.md                          ← 本文件 (目录说明)
├── cmd/
│   ├── scheduler/                     ← 定时任务调度器 (cron 注册 + 心跳)
│   │   └── README.md
│   └── job/                           ← 任务执行器 (handler 真正干活的)
│       └── README.md
└── pkg/                               ← (未来预留) 跨进程通用代码
```

| 进程 | 角色 | 数量 | 缩放 |
|------|------|------|------|
| mqueue-scheduler | 定时调度的"心跳" | 单实例就够 | ❌ 多个反而触发重复任务 |
| mqueue-job | 真正执行业务 handler | 可水平扩 | ✅ concurrency 可调 |

> 一个生成任务 (scheduler)，一个消费任务 (job)，按 cron 表达式 → Redis ZSET → handler 链路跑。

---

## 支持的 3 类任务

参见 [`cmd/job/jobtype/jobtype.go`](cmd/job/jobtype/jobtype.go)：

| 类型 | 常量前缀 | 触发方 | 用途 | 示例 |
|------|---------|--------|------|------|
| **cron** (定时) | `schedule:` | scheduler 启动时注册 cron | 周期执行 | `schedule:settle_record:settle` (每分钟) |
| **defer** (延迟) | `defer:` | 业务代码 `asynq.Enqueue(..., ProcessIn(N*time.Minute))` | 未来某时刻执行 | `defer:homestay_order:close` (15/30 分钟后) |
| **queue** (即时) | `msg:` | 业务代码 `asynq.Enqueue(...)` | 立即异步执行 | `msg:pay_success:notify_user` (支付通知) |

---

## 启动 / 关闭

| 动作 | 命令 |
|------|------|
| 跟其他 11 个 binary 一起 | `./scripts/dev-up.sh` |
| 单独启 scheduler | `go build -o ./tmp/mqueue-scheduler ./app/mqueue/cmd/scheduler && ./tmp/mqueue-scheduler -f ./app/mqueue/cmd/scheduler/etc/mqueue.yaml` |
| 单独启 job | `go build -o ./tmp/mqueue-job ./app/mqueue/cmd/job && ./tmp/mqueue-job -f ./app/mqueue/cmd/job/etc/mqueue.yaml` |
| 全停 | `./scripts/dev-down.sh` |

---

## 调试 — 优先看 Redis 状态

mqueue 的所有状态都在 Redis 里 (key 前缀 `asynq:`)，先列再查。

```bash
# 列所有相关 keys
docker exec -e REDISCLI_AUTH=G62m50oigInC30sf redis redis-cli KEYS 'asynq:*' | sort

# 关键 key (注意 {default} namespace 是本项目 asynq 版本的特点):
#   - asynq:{default}:scheduled         ZSET  待执行 (defer / cron)
#   - asynq:{default}:pending           LIST  立即要执行的
#   - asynq:{default}:retry             ZSET  失败待重试
#   - asynq:{default}:processed:DATE    SET   当日完成数
#   - asynq:{default}:t:<taskID>        HASH  单个任务详情
#   - asynq:schedulers:{host}:{pid}:..  HASH  scheduler 注册的 cron
#   - asynq:servers:{host}:{pid}:..     HASH  job worker 在线证明
#   - asynq:workers                     SET   活跃 workers

# 查 worker 是否在线
docker exec -e REDISCLI_AUTH=G62m50oigInC30sf redis redis-cli KEYS 'asynq:servers:*'
```

> ⚠️ 注意: 本项目用的 asynq 版本 (`hibiken/asynq` + go-zero 集成) 用 `asynq:{<queue>}:...` 命名空间。
> 旧资料里写的 `asynq:scheduled` / `asynq:queues:default` 等扁平 key 在本项目里**不存在**。

---

## 给"加新 mqueue 任务"的人

加新定时任务:
1. `app/mqueue/cmd/scheduler/internal/logic/xxxJob.go` —— 写 cron 注册逻辑
2. `app/mqueue/cmd/job/jobtype/jobtype.go` —— 加常量 (e.g. `ScheduleXxx`)
3. `app/mqueue/cmd/job/internal/logic/xxxHandler.go` —— 写 handler
4. `app/mqueue/cmd/job/internal/logic/routes.go` —— 加 `mux.Handle`

加业务侧触发 (defer/queue):
1. `app/{business}/cmd/{rpc|api}/internal/svc/serviceContext.go` —— 加 `AsynqClient`
2. 业务 logic 里调 `asynq.Enqueue(...)`

详见 [`cmd/scheduler/README.md`](cmd/scheduler/README.md) 和 [`cmd/job/README.md`](cmd/job/README.md)。

---

## 相关文档

- [`../../../notes/upgrade-journal/step-06-async-event-deep-dive.md`](../../../notes/upgrade-journal/step-06-async-event-deep-dive.md) —— 异步事件深度学习笔记 (含 asynq 调试方法论)
- [`../../../doc/chinese/08-消息-延迟-定时队列.md`](../../doc/chinese/08-消息-延迟-定时队列.md) —— Mikael 的教程原文
