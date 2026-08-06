# mqueue-scheduler

> 异步任务调度器：把 cron 表达式翻译成 asynq 注册项

---

## 业务场景

把"定时执行"和"业务代码"解耦：
- 业务代码**只**负责声明"我要这任务按多久跑一次"
- scheduler 进程**只**负责"按 cron 把任务塞进 asynq"
- 真正执行任务的是 [job 进程](../job/README.md)

实际例子（每分钟给商家生成结算记录）：
- scheduler 每分钟到点，发一条 `schedule:settle_record:settle` 任务
- job 那边 handler 收到就执行结账逻辑

> 为什么拆 2 个进程？scheduler 是 cron 心跳（轻量、定时），
> job 是业务执行（重、各种 handler）。拆开后**可独立伸缩**：
> 比如 cron 不需要多个实例（防重复触发），但 job 可以开 N 个 worker。

---

## 它做了什么

```
+--------------------+        每分钟       +-------------------------+
| scheduler 进程     |  ─── cron 到点 ──► |  Redis asynq:{default}  |
|                    |                    |  :scheduled ZSET        |
| 1. Read cron exprs |                    +-------------------------+
| 2. Register 任务   |                               │
| 3. 心跳 (asynq     |                               ▼
|    Scheduler.Run)  |                    +-------------------------+
|                    |                    |  job 进程               |
|                    |                    |  (AsynqServer.Run)      |
+--------------------+                    +-------------------------+
```

---

## 当前注册的任务

只有 1 个：

| 文件 | Task Type | Cron | 作用 |
|------|-----------|------|------|
| [`settleRecordJob.go`](internal/logic/settleRecordJob.go) | `schedule:settle_record:settle` | `*/1 * * * *` (每分钟) | 给商家结算 demo (目前是个空 demo, 留待业务实现) |

要加新任务:
1. 在 [`internal/logic/`](internal/logic/) 建新文件 `xxxJob.go`
2. 写 `func (l *MqueueScheduler) xxxJob() { l.svcCtx.Scheduler.Register(cron, task) }`
3. 改 [`register.go`](internal/logic/register.go) 的 `Register()` 加一行

---

## 怎么启动

```bash
# 方式 A: 一键 (跟其他 10 个 binary 一起, 用 dev-up.sh)
/bin/zsh -c './scripts/dev-up.sh'

# 方式 B: 单独启动 (排错时用)
go build -o ./tmp/mqueue-scheduler ./app/mqueue/cmd/scheduler
./tmp/mqueue-scheduler -f ./app/mqueue/cmd/scheduler/etc/mqueue.yaml
```

启动后会看到:

```
【settleRecordScheduler】 registered an  entry: "1ce0e617-..."
asynq: pid=NNN 2026/08/XX HH:MM:SS INFO: Scheduler starting
asynq: pid=NNN 2026/08/XX HH:MM:SS INFO: Scheduler timezone is set to Asia/Shanghai
asynq: pid=NNN 2026/08/XX HH:MM:SS INFO: Send signal TERM or INT to stop the scheduler
```

---

## 怎么验证

**1. 看 Redis 里的 cron entry** (确认 cron 已注册):

```bash
docker exec -e REDISCLI_AUTH=G62m50oigInC30sf redis redis-cli \
  ZRANGE 'asynq:schedulers:{你的hostname}:{pid}:{uuid}' 0 -1 WITHSCORES
# 应该有 1 个 cron entry (含 cron 表达式 + task type)
```

**2. 等 1 分钟, 看 scheduled ZSET** (确认 cron 触发了任务):

```bash
docker exec -e REDISCLI_AUTH=G62m50oigInC30sf redis redis-cli \
  ZRANGE 'asynq:{default}:scheduled' 0 -1 WITHSCORES
```

---

## 怎么调试

**症状: scheduler 没起来**

```bash
# 1. 看 log (dev-up.sh 修过后有 log, v3.9 之前是空白)
tail -n 50 tmp/logs/mqueue-scheduler.log

# 2. 看 Redis 注册了没
docker exec -e REDISCLI_AUTH=G62m50oigInC30sf redis redis-cli \
  KEYS 'asynq:schedulers:*'

# 3. 看 redis.Redis 密码对不对
grep -A 3 "^Redis:" app/mqueue/cmd/scheduler/etc/mqueue.yaml
```

**症状: cron 到点了任务没触发**

```bash
# 1. cron 表达式对不对? 推荐用 crontab.guru 验证
# 2. 时区对不对 (本项目用 Asia/Shanghai, 见 svc/scheduler.go)
# 3. 看 job 进程是不是活着 (scheduler 推完任务, 没活 worker 会积压在 Redis)
ps aux | grep mqueue-job | grep -v grep
```

---

## 文件结构

```
app/mqueue/cmd/scheduler/
├── README.md                       ← 本文件
├── mqueue.go                       ← main entry
├── etc/
│   └── mqueue.yaml                 ← 配置 (Redis addr + Prometheus port 4011)
└── internal/
    ├── config/                     ← yaml 结构 + SetUp (log/prom/trace)
    ├── svc/
    │   ├── serviceContext.go       ← asynq.Scheduler 实例化 (Redis 连接)
    │   └── scheduler.go            ← asynq.NewScheduler + Location
    └── logic/
        ├── register.go             ← MqueueScheduler.Register() 入口
        ├── settleRecordJob.go      ← 示例: 结算 cron
        └── (未来) xxxJob.go        ← 你的新 cron
```

---

## 相关文档

- [`../../../notes/upgrade-journal/step-06-async-event-deep-dive.md`](../../../notes/upgrade-journal/step-06-async-event-deep-dive.md) §3 异步事件家族
- [job README](../job/README.md) —— 任务真执行者
- [asynq 文档](https://github.com/hibiken/asynq) —— `Scheduler` 和 `Scheduler.Register` API
