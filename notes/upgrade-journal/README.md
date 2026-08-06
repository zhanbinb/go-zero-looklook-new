# go-zero-looklook 升级日志（upgrade-journal）

> 把 Mikaelemmmm/go-zero-looklook 从 2022-2023 的 v1 状态，升级到 2026 年的现代 Go 微服务栈。
> 一边升级，一边学习。

## 🎯 当前路线（2026-08-05 重新规划）

**新战略**：从"库升级优先"切换到"业务闭环优先"。

完整思路见 **[`step-replan-2026-08-05.md`](step-replan-2026-08-05.md)**。

新优先级：
```
A. 业务闭环（ch 4-8）     ⏳ 当前 P0   跑通 5 个服务 + e2e
B. 基础设施贯通（ch 11-13）⏸️ P1     接 ELK + OTel + Prom
C. 纯库升级（4d 等）       ⏸️ P2     业务跑通后再做
```

## 已完成清单（history）

| Step | 标题 | 状态 |
|------|------|------|
| 0    | v1 baseline             | ✅ |
| 1    | dev env (11 中间件)     | ✅ |
| 1.5  | JWT 中间件验证          | ✅ |
| 2    | modd → air              | ✅ |
| 2.5  | air 单文件统一          | ✅ |
| 99   | 清理 92M 二进制         | ✅ |
| 4a   | go-zero 1.7.3 → 1.10.2  | ✅ |
| 4b   | jwt v4 → v5             | ⏸️ deferred（go-zero 内部仍 v4）|
| 4c   | go-redis v8 → v9        | ✅（业务通过 go-zero wrapper 已生效）|
| 4d   | pkg/errors → std errors | 🚧 usercenter 试点完成，**全量暂缓**（等业务闭环后做）|
| 99b  | step-05 M1.1-1.6 smoke 全活              | ✅ |
| 99c  | step-06 异步事件深度学习 (api-rpc 链 + asynq + Kafka) | ✅ |
| v3.12 | Kafka Brokers 真实 bug fix (kafka:9092→127.0.0.1:9094) | ✅ |

## 项目结构

```
go-zero-looklook-study/
├── go-zero-looklook/         # v1 原项目（git clone 下来的基线，只读参照）
└── notes/upgrade-journal/    # 本目录：升级过程的所有记录
    ├── README.md             # 本文件（v2 重写，2026-08-05）
    ├── step-replan-2026-08-05.md   # ⭐ 新战略文档
    ├── step-00-v1-baseline.md
    ├── step-01-env-setup.md
    ├── step-01.5-jwt-validation.md
    ├── step-02-air-trial.md
    ├── step-02.5-air-single-file.md
    ├── step-02.5-air-unified-done.md
    ├── step-03-docker-dev-mode.md        # ⏸️ deferred（M8 评估）
    ├── step-04a-go-zero-upgrade.md
    ├── step-04b-jwt-v5-deferred.md
    ├── step-04c-go-redis-v9-status.md
    ├── step-04d-pkg-errors-migration.md  # 试点完成，全量待业务跑通后
    ├── step-05-business-baseline.md        # M1 working doc (✅ closed)
    ├── step-06-async-event-deep-dive.md    # 异步事件学习 (api→rpc链 + asynq + Kafka)
    ├── step-99-cleanup-history.md
    ├── progress-day-1.md
    ├── cheatsheet-kafka.md
    ├── compare/                # 升级前后代码对比（待补）
    └── patches/                # 升级用的 diff / 修复文件（待补）
```

## 工作约定

- 所有"动手"操作在 `go-zero-looklook-new/` 目录
- v1 参照读 `go-zero-looklook-study/go-zero-looklook/`（只读，不动）
- 升级决策记录在 `compare/` 和 `patches/` 目录
- 每篇 step 笔记固定格式：目标 / 改动文件 / 关键 diff / 踩坑 / 验证 / 时长
- **真理来源**：`doc/chinese/` 下 15 章教程 + 我们自己的 step 笔记

## 当前状态（M1 收尾中）

**最近 commit (v3.12)**：
- `scripts/dev-up.sh` 把服务 stdout/stderr 重定向到 `tmp/logs/<name>.log` (v3.9)
- Kafka Brokers 修 `kafka:9092 → 127.0.0.1:9094` (v3.12, 真实 bug)
- M1 全活闭环 5/5 服务 + closeOrder 实验验证 (60s 内 trade_state 0→-1)
- 异步事件全部摸清 + asynq `{default}` 命名空间这一发现沉淀进 step-06

**当前进度**：M1 已 **完全收尾**（包含 Kafka Brokers fix + closeOrder 实验）

**M1 完成清单 (ground truth)**：
- ✅ 11 个 binary 全编译
- ✅ 11 个 binary 全活（dev-up.sh 起，tmp/logs/ 有 log）
- ✅ 5 个 service smoke 全通（5/7，剩 commentList 空 stub 跳过 + payment 缺 e2e）
- ✅ M1.6 实验验证 ⑨⑩ 真活:
   - M1-1: `asynq:{default}:scheduled` ZSET 有 defer 任务 (id + process_at 一致)
   - M1-3: CloseOrderTimeMinutes=1, trade_state 60s 内 0→-1
- ✅ Kafka Brokers 修 (order-mq kq consumer + payment-rpc Push 都通)

**下一步 (M2 候选)**：跨 5 服务一笔订单联通 (browse → order → pay → settle)
详细规划见 [step-replan-2026-08-05.md](step-replan-2026-08-05.md) § 2 视角 A。

完整细节见 [`step-05-business-baseline.md`](step-05-business-baseline.md)。

## 已知未完成（按新优先级）

- [ ] **P0**: M1 — 5 个服务全 air 起来，11 个 binary 全活（travel/payment/order/mqueue 还都没起过）
- [ ] **P1**: M2-M4 — RPC 联调 → e2e 业务线 → 业务代码全读懂 ch 4-8
- [ ] **P1**: ch 12 修 OTel，ch 11 接日志，ch 13 验证 prom
- [ ] **P2**: ch 2 nginx 网关（评估 APISIX 替换）
- [ ] **P2**: Step 4d 全量（业务跑通后做真实回归）
- [ ] **P3**: 生产部署（ch 14-15，本期大概率跳过）
- [ ] **P3**: jwt v5 / asynq 升级（free-floating）

## git 状态

```
$ git log --oneline -5
a24da59 v3.8: air unified - .air.toml 管全部服务 + telemetry Endpoint 修复
8211415 v3.7: docs - step-02.5 air single-file roadmap (modd.conf style)
0bf4f58 v3.6: air 同时启 usercenter rpc + api (脚本编排) + 9 个 yaml 改 host 端口
8695336 v3.5: docs - step-03-docker-dev-mode.md (全 Docker 模式 roadmap)
eca2a12 v3.4: docs - step-99-cleanup-history.md (记录 92M 清理)
...
```

---

*此 README 在 2026-08-05 重写，从"线性 Step 1-5"切换到"3 层视角 (A/B/C)"。*
*老 step 笔记全部保留作为历史，未删除任何内容。*
