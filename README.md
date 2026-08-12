# go-zero-looklook-new

> **开箱即用的工业级 Go 微服务样板**：完整的业务闭环 + 现代化可观测性（metrics / logs / traces / alerts），2026 年主流技术栈版本，clone 即可作为新项目基线。

<!-- ─────────── Core ─────────── -->
[![Go](https://img.shields.io/badge/Go-1.24-00ADD8?logo=go&logoColor=white)](https://go.dev)
[![go-zero](https://img.shields.io/badge/go--zero-v1.10.2-0088CC?logo=go&logoColor=white)](https://github.com/zeromicro/go-zero)
[![JWT](https://img.shields.io/badge/JWT-HS256-000000?logo=jsonwebtokens&logoColor=white)](https://jwt.io/)

<!-- ─────────── Storage ─────────── -->
[![MySQL](https://img.shields.io/badge/MySQL-8.0.28-4479A1?logo=mysql&logoColor=white)](https://www.mysql.com/)
[![Redis](https://img.shields.io/badge/Redis-6.2.5-DC382D?logo=redis&logoColor=white)](https://redis.io/)
[![Apache Kafka](https://img.shields.io/badge/Kafka-3.9.0-231F20?logo=apachekafka&logoColor=white)](https://kafka.apache.org/)
[![Elasticsearch](https://img.shields.io/badge/Elasticsearch-8.12.2-005571?logo=elasticsearch&logoColor=white)](https://www.elastic.co/elasticsearch/)

<!-- ─────────── Observability ─────────── -->
[![Prometheus](https://img.shields.io/badge/Prometheus-v2.55.1-E6522C?logo=prometheus&logoColor=white)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-11.4.0-F46800?logo=grafana&logoColor=white)](https://grafana.com/)
[![Jaeger](https://img.shields.io/badge/Jaeger-1.63-66CBE3?logo=jaeger&logoColor=white)](https://www.jaegertracing.io/)
[![Kibana](https://img.shields.io/badge/Kibana-8.12.2-005571?logo=kibana&logoColor=white)](https://www.elastic.co/kibana/)
[![OpenTelemetry](https://img.shields.io/badge/OpenTelemetry-OTLP-425CC7?logo=opentelemetry&logoColor=white)](https://opentelemetry.io/)
[![filebeat](https://img.shields.io/badge/filebeat-8.12.2-00BFB3?logo=elastic-stack&logoColor=white)](https://www.elastic.co/beats/filebeat/)

<!-- ─────────── Infrastructure ─────────── -->
[![Docker](https://img.shields.io/badge/Docker-≥_4.x-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![nginx](https://img.shields.io/badge/nginx-1.21.5-009639?logo=nginx&logoColor=white)](https://nginx.org/)
[![air](https://img.shields.io/badge/air-latest-00ADD8?logo=go&logoColor=white)](https://github.com/cosmtrek/air)

<!-- ─────────── Repo ─────────── -->
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Release](https://img.shields.io/badge/Release-v3.41-blue)](https://github.com/zhanbinb/go-zero-looklook-new/releases)
[![Last Commit](https://img.shields.io/github/last-commit/zhanbinb/go-zero-looklook-new)](https://github.com/zhanbinb/go-zero-looklook-new/commits/main)
[![Code Size](https://img.shields.io/github/languages/code-size/zhanbinb/go-zero-looklook-new)](https://github.com/zhanbinb/go-zero-looklook-new)
[![Repo Size](https://img.shields.io/github/repo-size/zhanbinb/go-zero-looklook-new)](https://github.com/zhanbinb/go-zero-looklook-new)
[![Go Report Card](https://goreportcard.com/badge/github.com/zhanbinb/go-zero-looklook-new)](https://goreportcard.com/report/github.com/zhanbinb/go-zero-looklook-new)
[![GitHub Stars](https://img.shields.io/github/stars/zhanbinb/go-zero-looklook-new?style=social)](https://github.com/zhanbinb/go-zero-looklook-new/stargazers)

---

## 🎯 Features

- ✅ **完整的微服务架构**：5 个业务服务 / 11 个二进制 / REST + RPC 混合调用 / JWT 鉴权 / 统一错误处理
- ✅ **统一的可观测性**：metrics + logs + traces + **alerts** 全跑通且互相对应
- ✅ **告警闭环**：端到端验证的 firing + resolved webhook（payload 已渲染好，可直接对接飞书/钉钉/Slack）
- ✅ **开箱即用的开发体验**：docker compose 一键起 11 个中间件、air 热重载、`dev-e2e.sh` 端到端回归 8/8 PASS
- ✅ **生产级的依赖版本**：Go 1.24 + go-zero 1.10.2 + Prometheus v2.55.1 + Grafana 11.4 + Elasticsearch 8 + Kafka 3.9 + Jaeger 1.63
- ✅ **多协议网关**：nginx `auth_request` 默认方案 + APISIX 可一键替换（已实战对比）
- ✅ **混合消息队列**：Kafka 流式消息（`kq`）+ asynq 延迟 / 定时任务（基于 Redis）
- ✅ **数据全部本地化**：所有中间件数据挂载到 `./data/` 目录，无状态容器，迁移 / 备份 / 重置都简单
- ✅ **配置可入 git**：所有 yaml / 配置文件格式友好，方便 diff 和 review

---

## 💼 Use Cases

**适合用作**：

- 🏢 **企业级 Go 微服务脚手架** — 5 个服务的拓扑可作为新项目起点，直接增删改成你的业务
- 🚀 **go-zero 生产参考** — 真实业务系统怎么落地 observability，4 件套全部跑通可对照
- 🔄 **2022 老 stack 升级参考** — 从 go-zero 1.7 / Grafana 8 / Prom 2.28 升到 2026 现代 stack 的完整路径（22 篇 step 笔记）
- 🧪 **可观测性 PoC / Demo** — metrics / logs / traces / alerts 数据流互相印证，可用于团队技术评审

**不太适合**：

- ❌ go-zero 入门上手（请直接看 [go-zero 官方文档](https://go-zero.dev) 或社区教程）
- ❌ 单体小项目（这套架构过重）
- ❌ k8s 原生部署（ch 14-15 暂未实现，路线见 [step-replan](notes/upgrade-journal/step-replan-2026-08-05.md)）

---

## 📖 项目概览

本仓库基于 [Mikaelemmmm/go-zero-looklook](https://github.com/Mikaelemmmm/go-zero-looklook) 的业务拓扑（民宿短租场景），把整个技术栈从 2022-2023 年的旧版升级到 2026 主流版本，并补齐了原版缺失的可观测性最后一块——**告警链路**。

**核心组成**：

| 维度 | 内容 |
|---|---|
| 业务服务 | order / payment / travel / usercenter / mqueue |
| 存储 | MySQL + Redis + Kafka + Elasticsearch |
| 鉴权 | JWT (HS256) via go-zero middleware |
| 协议 | REST + gRPC + Kafka + Redis Stream |
| 可观测 | Prometheus + Grafana + Jaeger + Kibana + filebeat + go-stash + 内置 Alertmanager |
| 网关 | nginx `auth_request`（默认） / APISIX（已对比）|

---

## 🎯 技术栈

### 业务框架层

| 组件 | 版本 | 用途 |
|---|---|---|
| [go-zero](https://github.com/zeromicro/go-zero) | v1.10.2 | 微服务框架（rest / rpc / kq / asynq / otel 全套集成）|
| [go-zero/contrib](https://github.com/zeromicro/go-zero) | latest | JWT / 限流 / 鉴权 中间件 |
| [go-redis](https://github.com/redis/go-redis) | v9 | Redis 客户端（go-zero wrapper 已封装）|
| [confluent-kafka-go](https://github.com/segmentio/kafka-go) | via kq | Kafka 客户端（go-zero kq 封装）|
| [hibiken/asynq](https://github.com/hibiken/asynq) | latest | 基于 Redis 的延迟队列 / 定时任务 |
| [golang-jwt](https://github.com/golang-jwt/jwt) | v5 | JWT 签发 / 验证 |
| [go-zero/errorx](https://github.com/zeromicro/go-zero) | builtin | 统一错误处理（保留 stack）|
| [validator](https://github.com/go-playground/validator) | v10 | 请求参数校验 |

### 存储层

| 组件 | 版本 | 用途 | 端口 |
|---|---|---|---|
| [MySQL](https://www.mysql.com/) | 8.0.28 | 业务数据 | `33069` (host) → `3306` (container) |
| [Redis](https://redis.io/) | 6.2.5 | 缓存 + asynq 队列 | `36379` (host) → `6379` (container) |
| [Kafka](https://kafka.apache.org/) | 3.9.0 (KRaft 模式) | 消息流 | `9094` (host, PLAINTEXT) / `9092` (container, PLAINTEXT_CONTAINER) |
| [Elasticsearch](https://www.elastic.co/elasticsearch/) | 8.12.2 | 日志 / 链路 / 业务搜索 | `9200` |

### 可观测性层

| 组件 | 版本 | 用途 | 端口 |
|---|---|---|---|
| [Prometheus](https://prometheus.io/) | v2.55.1 | 指标采集 + 存储 + PromQL 查询 | `9090` |
| [Grafana](https://grafana.com/) | 11.4.0 | Dashboard + **Unified Alerting**（内置 Alertmanager）| `3001` (admin / admin) |
| [Jaeger](https://www.jaegertracing.io/) | 1.63 (all-in-one + ES backend) | 链路追踪 + Trace UI | `16686` (UI) / `4318` (OTLP HTTP) |
| [Kibana](https://www.elastic.co/kibana/) | 8.12.2 | 日志查询 + Dashboard | `5601` |
| [filebeat](https://www.elastic.co/beats/filebeat/) | 8.12.2 | host 业务日志 + docker 容器日志采集 | — |
| [kevinwan/go-stash](https://github.com/kevinwan/go-stash) | 1.1.1 | Kafka → ES 数据清洗管道（替代 logstash，资源占用 -90%）| — |
| [asynqmon](https://github.com/hibiken/asynqmon) | latest | asynq Web UI（队列 / 任务面板）| `8980` |
| [kafka-ui](https://github.com/provectus/kafka-ui) | latest | Kafka Web UI（topic / consumer / schema）| `8082` |

### 基础设施层

| 组件 | 版本 | 用途 |
|---|---|---|
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | ≥ 4.x | 中间件容器化（macOS / Windows / Linux）|
| [Go](https://go.dev/dl/) | 1.24 | 业务编译 / 运行 |
| [air](https://github.com/cosmtrek/air) | latest | Go 热重载（取代 modd）|
| [nginx](https://nginx.org/) | 1.21.5 | 反向代理 + `auth_request` 鉴权 |
| [OpenTelemetry](https://opentelemetry.io/) | OTLP HTTP | Trace 导出（不依赖 collector，直接到 Jaeger）|

---

## 🏗️ 架构

### 业务服务拓扑（5 服务 / 11 二进制）

```
                  ┌──────────────────────────────────────────────────┐
                  │           nginx-gateway (:8888)                  │
                  │      auth_request → usercenter-rpc 校验 JWT       │
                  └──────────────────────────────────────────────────┘
                                            │
              ┌──────────────┬──────────────┼──────────────┬──────────────┐
              ▼              ▼              ▼              ▼              ▼
       usercenter-api   travel-api    order-api     payment-api    (前端 / BFF)
         :1004            :1003         :1001          :1002
              │              │              │              │
              ▼              ▼              ▼              ▼
       usercenter-rpc   travel-rpc    order-rpc    payment-rpc
         :2004            :2003         :2001          :2002
                                              │
                                              ▼
                                       order-mq  ◄─── Kafka: payment-update-paystatus-topic
                                              │
                                              ▼
                                  mqueue-scheduler (cron) ──┐
                                  mqueue-job (worker) ◄─────┘
                                       │   ▲
                                       ▼   │
                                   Redis (asynq)
```

### 可观测性数据流

#### 📝 日志管道（app → Kibana）

```
┌─────────────────┐
│ 11 个 go-zero   │  stdout 写到 tmp/logs/*.log
│ binary (host)   │
└────────┬────────┘
         │
         ▼ bind mount /var/log/looklook
┌─────────────────┐
│  filebeat 8.12  │  两个 input：业务日志 + docker 容器 JSON 日志
│  (container)    │
└────────┬────────┘
         │ output.kafka
         ▼
┌──────────────────────────────────────────┐
│  Kafka 3.9  topic: looklook-log          │
│  16 partitions, gzip compression         │
└────────┬─────────────────────────────────┘
         │ consume
         ▼
┌─────────────────┐
│  go-stash 1.1   │  filter: drop info+RPC, remove_field, transfer message→data
│  (container)    │
└────────┬────────┘
         │ output.elasticsearch
         ▼
┌──────────────────────────────────────────┐
│  ES 8.12  index: looklook-{yyyy-MM-dd}   │
│  按天切，每天自动 rollover                │
└────────┬─────────────────────────────────┘
         │ query (KQL / Lucene)
         ▼
┌─────────────────┐
│  Kibana 8.12    │  data view: looklook-* @timestamp
│  :5601          │  可视化、搜索、留存管理
└─────────────────┘
```

#### 🔗 链路追踪（app → Jaeger）

```
┌─────────────────┐
│  go-zero 服务   │  Telemetry 段：Batcher=otlphttp, Sampler=1.0
│ (host binary)   │  通过 OTLP HTTP 协议导出 span
└────────┬────────┘
         │ POST http://jaeger:4318/v1/traces
         ▼
┌──────────────────────────────────────────┐
│  Jaeger 1.63 Collector (all-in-one)      │
│  SPAN_STORAGE_TYPE=elasticsearch          │
└────────┬─────────────────────────────────┘
         │ write
         ▼
┌──────────────────────────────────────────┐
│  ES 8.12  index: jaeger-*                │
│  (与日志索引共享集群)                      │
└────────┬─────────────────────────────────┘
         │ query
         ▼
┌─────────────────┐
│  Jaeger UI      │  :16686 服务拓扑 + span 时序
│                 │  按 service / operation / tag 过滤
└─────────────────┘
```

#### 📈 指标采集（app → Grafana）

```
┌─────────────────┐
│  go-zero 服务   │  Prometheus 段：Host=0.0.0.0 Port=4001..4011
│ (host binary)   │  自动监听 /metrics, 无需额外代码
└────────┬────────┘
         │ scrape_interval=15s
         ▼
┌──────────────────────────────────────────┐
│  Prometheus v2.55.1                       │
│  12 个 scrape target（11 服务 + 自身）      │
│  抓取容器 → host 用 host.docker.internal    │
└────────┬─────────────────────────────────┘
         │ PromQL via HTTP datasource
         ▼
┌─────────────────┐
│  Grafana 11.4   │  数据源: http://prometheus:9090 (容器内访问)
│  :3001          │  Dashboard: "looklook go-zero" (7 panel)
│                 │  + Unified Alerting（见下）
└─────────────────┘
```

#### 🚨 告警链路（rule → webhook）

```
┌─────────────────┐
│ Prometheus 指标 │  例如: up{job="mqueue-scheduler"}
└────────┬────────┘
         │ PromQL 查询
         ▼
┌──────────────────────────────────────────────────────────┐
│  Grafana 11.4 Alert Rule                                  │
│  表达式: last(up{job="mqueue-scheduler"}) < 1             │
│  触发条件: 持续 1 分钟（pending period）                    │
│  NoDataState: OK, ExecErrState: Error                     │
└────────┬─────────────────────────────────────────────────┘
         │ state: Normal → Pending → Firing
         ▼
┌──────────────────────────────────────────────────────────┐
│  Grafana 内置 ngalert (Alertmanager)                      │
│  Notification Policy 默认路由到 mock-webhook              │
└────────┬─────────────────────────────────────────────────┘
         │ 渲染 payload (title + message + Silence URL)
         ▼
┌──────────────────────────────────────────────────────────┐
│  Contact Point: webhook → http://host.docker.internal:9999│
│  sendResolved=true (firing + resolved 都发)              │
└────────┬─────────────────────────────────────────────────┘
         │ HTTP POST
         ▼
┌─────────────────┐
│ 飞书 / 钉钉 /   │  payload 中的 title 和 message 已渲染好
│ Slack / 邮件    │  直接拿去当通知正文
└─────────────────┘
```

### 网络与端口

```
┌─ Host machine ──────────────────────────────────────────────────────┐
│                                                                      │
│  business (host)             observability (host→container)          │
│  ├─ usercenter-api  :1004     Prometheus    127.0.0.1:9090         │
│  ├─ usercenter-rpc  :2004     Grafana       127.0.0.1:3001         │
│  ├─ travel-api      :1003     Kibana        127.0.0.1:5601         │
│  ├─ travel-rpc      :2003     Jaeger UI     127.0.0.1:16686        │
│  ├─ order-api       :1001     asynqmon      127.0.0.1:8980         │
│  ├─ order-rpc       :2001     kafka-ui      127.0.0.1:8082         │
│  ├─ order-mq        (bg)      ES            127.0.0.1:9200         │
│  ├─ payment-api     :1002     nginx-gateway 127.0.0.1:8888         │
│  ├─ payment-rpc     :2002                                                │
│  ├─ mqueue-scheduler (bg)     mysql/redis (host loopback)             │
│  └─ mqueue-job      (bg)                                                │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
                                       │
                                       │ docker compose -f docker-compose-env.yml
                                       ▼
┌─ Docker network: looklook_net ───────────────────────────────────────┐
│                                                                      │
│  prometheus  :9090   grafana :3000   kibana :5601                    │
│  jaeger    :16686 /4317/4318   elasticsearch :9200                   │
│  kafka     :9092/9094   go-stash  filebeat                          │
│  mysql     :3306   redis :6379                                       │
│  nginx-gateway :8081   asynqmon :8080   kafka-ui :8080             │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 快速开始

### 前置条件

- **OS**：macOS / Linux（Windows 需 WSL2）
- **Docker Desktop** ≥ 4.x（[下载](https://www.docker.com/products/docker-desktop/)）
- **Go** 1.24（[下载](https://go.dev/dl/)）
- **air**：`go install github.com/cosmtrek/air@latest`
- 国内用户建议配置 Docker Hub mirror（首次拉镜像）

### 三步启动

```bash
# 1. 启动 11 个中间件容器（首次约 2 min）
docker compose -f docker-compose-env.yml up -d

# 2. 编译 11 个二进制（首次约 3 min）
./scripts/dev-build.sh

# 3. 启动 11 个服务（air 也可）
./scripts/dev-up.sh
```

### 验证

```bash
./scripts/dev-status.sh           # 看服务端口 + 进程全活
./scripts/dev-e2e.sh              # 跑 8 个端到端检查点，预期 8/8 PASS
```

### 访问入口

| 类别 | URL | 凭证 |
|---|---|---|
| 业务 API（任一） | `http://127.0.0.1:1001-1004` | — |
| 业务 RPC | `127.0.0.1:2001-2004` | — |
| Grafana | `http://127.0.0.1:3001` | `admin` / `admin` |
| Prometheus | `http://127.0.0.1:9090` | — |
| Kibana | `http://127.0.0.1:5601` | — |
| Jaeger | `http://127.0.0.1:16686` | — |
| asynqmon（队列面板）| `http://127.0.0.1:8980` | — |
| kafka-ui | `http://127.0.0.1:8082` | — |
| nginx-gateway | `http://127.0.0.1:8888` | — |

---

## 📁 项目结构

```
go-zero-looklook-new/
├── app/                          # 业务代码
│   ├── order/                    # 订单服务
│   │   └── cmd/{api,rpc,mq}/     # 3 个二进制
│   ├── payment/                  # 支付服务
│   │   └── cmd/{api,rpc}/
│   ├── travel/                   # 民宿服务
│   │   └── cmd/{api,rpc}/
│   ├── usercenter/               # 用户中心
│   │   └── cmd/{api,rpc}/
│   └── mqueue/                   # 后台任务
│       └── cmd/{scheduler,job}/
├── pkg/                          # 公共包
├── deploy/                       # 部署 / 中间件配置
│   ├── prometheus/server/        # Prometheus 配置
│   ├── filebeat/conf/            # filebeat 配置
│   ├── go-stash/etc/             # kafka→ES 清洗
│   ├── nginx/conf.d/             # nginx-gateway
│   └── ...
├── doc/                          # 上游原版的章节说明文档
│   └── chinese/                  # 15 章 markdown（架构 / 业务 / 部署参考）
├── notes/upgrade-journal/        # 本仓库的 22 篇 step 笔记（演进日志）
├── scripts/                      # 启停 / 回归脚本
│   ├── dev-up.sh / dev-down.sh
│   ├── dev-build.sh / dev-status.sh
│   ├── dev-e2e.sh                # 端到端 8 检查点
│   └── ...
├── docker-compose-env.yml        # 11 个中间件编排
├── docker-compose.yml            # 业务服务编排（host 模式，未启用）
├── go.mod / go.sum
├── .air.toml                     # air 配置
├── LICENSE                       # MIT
└── README.md                     # 本文件
```

---

## 📊 可观测性

我们实现了完整的 4 件套，**每一件都跑通 + 互相印证**。

### 📈 Metrics

- **采集**：每个 go-zero 服务暴露 `/metrics`（端口由 `Prometheus.Port` 配置）
- **抓取**：[`deploy/prometheus/server/prometheus.yml`](deploy/prometheus/server/prometheus.yml) 12 个 target 全 up
- **展示**：Grafana "looklook go-zero" dashboard（7 panel：QPS / 内存 / Goroutine / P95 延迟）
- **接入新服务**：加一个 `job_name` + 端口即可，详见 [开发指南](#🛠️-开发指南)

### 📝 Logs

- **采集**：[filebeat](deploy/filebeat/conf/filebeat.yml) 两个 input：业务日志 + docker 容器日志
- **管道**：filebeat → Kafka (`looklook-log`) → [go-stash](deploy/go-stash/etc/config.yaml) 清洗（drop / remove_field / transfer message→data） → ES `looklook-{yyyy-MM-dd}`
- **展示**：Kibana `looklook-*` data view
- **告警**：📋 Kibana Rules（评估中，详见 [step-21 §3.2](notes/upgrade-journal/step-21-alerting-assessment.md)）

### 🔗 Traces

- **采集**：各服务 `Telemetry` 段配 `Batcher=otlphttp, Sampler=1.0`
- **存储**：Jaeger 1.63（all-in-one + ES 后端）
- **展示**：[Jaeger UI :16686](http://127.0.0.1:16686)，支持服务拓扑 + span 时序

### 🚨 Alerts

> **状态**：✅ 端到端跑通（firing + resolved 双链路验证）
> 详情：[`notes/upgrade-journal/step-22-alerting-implementation.md`](notes/upgrade-journal/step-22-alerting-implementation.md)

| 组件 | 当前配置 |
|---|---|
| Contact Point | `mock-webhook` → `http://host.docker.internal:9999/` |
| Notification Policy | 默认路由到 mock-webhook |
| Alert Rule | `mqueue-scheduler-down`: `last(up{job="mqueue-scheduler"}) < 1` for 1m |

**生产化路径**：把 mock-webhook 的 URL 换成飞书/钉钉机器人 webhook，**payload 不用改**（已渲染好 `title` + `message` + `Silence URL`）。

---

## 🧪 测试与回归

| 脚本 | 用途 | 预期 |
|---|---|---|
| `./scripts/dev-build.sh` | 编译 11 个 binary | 0 错 |
| `./scripts/dev-up.sh` | 启 11 个服务 | 全部 listen |
| `./scripts/dev-status.sh` | 看服务端口 + 进程 | 全绿 |
| `./scripts/dev-e2e.sh` | 端到端 8 检查点 | **8/8 PASS** |
| `./scripts/dev-mq-trace.sh` | 看 mq 链路 | — |
| `./scripts/dev-apisix-up.sh` | 起 APISIX（对照 nginx）| — |

---

## ⚙️ 关键配置说明

### 中间件连接（各服务 yaml）

业务服务通过 host loopback 连接中间件（不走 docker 网络，host 直接访问）：

```yaml
Mysql:
  Host: 127.0.0.1
  Port: 33069         # 映射 docker 3306

Redis:
  Host: 127.0.0.1
  Port: 36379         # 映射 docker 6379
  Pass: G62m50oigInC30sf

Kafka:
  Brokers:
    - 127.0.0.1:9094  # 映射 docker 9092（PLAINTEXT 监听）
```

### Telemetry（链路追踪）

```yaml
Telemetry:
  Name: order-api              # 服务名（Jaeger 显示）
  Endpoint: 127.0.0.1:4318     # Jaeger OTLP HTTP
  Sampler: 1.0                 # 全量采样（dev）；生产改 probabilistic
  Batcher: otlphttp
```

### Prometheus（指标端点）

```yaml
Prometheus:
  Host: 0.0.0.0
  Port: 4001                   # 各 service 不同，见 deploy/prometheus/server/prometheus.yml
  Path: /metrics
```

### 时区

所有容器和业务都设 `TZ: Asia/Shanghai`（如需改时区，统一替换）。

---

## 📚 参考文档

本仓库 [`notes/upgrade-journal/`](notes/upgrade-journal/) 有 **22 篇 step 笔记**，按时间顺序记录了演进过程。

### 重点章节

| 章节 | 笔记 | 内容 |
|---|---|---|
| 业务闭环 | [step-05](notes/upgrade-journal/step-05-business-baseline.md) ~ [step-08](notes/upgrade-journal/step-08-complete-order-flow.md) | M1-M4：5 服务全活 → 跨服务一笔订单 e2e |
| 关账 / 回归 | [step-20](notes/upgrade-journal/step-20-m3-m4-e2e-regression.md) | M3/M4 关账 + `dev-e2e.sh` 回归基线 8/8 |
| 监控（ch 13）| [step-17](notes/upgrade-journal/step-17-ch13-monitoring.md) | Prometheus 12 target + Grafana 7 panel |
| 监控（升级 + 告警）| [step-22](notes/upgrade-journal/step-22-alerting-implementation.md) | **Grafana 11.4 + Prom 2.55 升级 + 告警链路** |
| 链路追踪（ch 12）| [step-18](notes/upgrade-journal/step-18-ch12-tracing.md) | Jaeger + OTLP HTTP |
| 日志收集（ch 11）| [step-19](notes/upgrade-journal/step-19-ch11-logging.md) | filebeat → Kafka → ES → Kibana |
| 评估 | [step-21](notes/upgrade-journal/step-21-alerting-assessment.md) | 告警三路线对比 + 推荐方案 |

### 上游原版说明

[`doc/chinese/`](doc/chinese/) 是上游原版 Mikaelemmmm/go-zero-looklook 的 15 章 markdown（业务架构、网关、消息队列、部署等的**原始章节说明**）。本仓库未删除，作为参考存档。

---

## 🛠️ 开发指南

### 热重载（air）

```bash
air  # 启 11 个服务，监听文件变化自动重启
```

配置：`.air.toml`

### 添加新 service

参考 `app/order/` 模板：

1. `app/<svc>/cmd/api/main.go` + `internal/handler/logic/`
2. `app/<svc>/cmd/rpc/main.go` + `internal/server/logic/`
3. `app/<svc>/cmd/api/etc/<svc>.yaml`（端口、JWT、Telemetry、Prometheus 段）
4. 在 `scripts/dev-up.sh` 的 NAMES / PIDS 数组加一行

### 加 Prometheus target

`deploy/prometheus/server/prometheus.yml` 加：

```yaml
- job_name: 'new-svc-api'
  static_configs:
    - targets: [ 'host.docker.internal:NNNN' ]
      labels:
        job: new-svc-api
        app: new-svc
        env: dev
```

### 加 Grafana 告警 rule

详见 [step-22 §4.3](notes/upgrade-journal/step-22-alerting-implementation.md) 的模板。注意 11.4 schema 几个陷阱：API 用扁平结构（不要 `groups: []` 包装）、`notificationSettings` 字段 API 会忽略（改默认 Policy 兜底）。

---

## 🤝 贡献

欢迎：

- 🐛 **报 issue** — 踩到的坑、文档错误、依赖漏洞
- 📝 **提 PR** — 修小错（typo / 链接过期 / 路径错误）
- 💡 **讨论** — 架构选择、升级路径、生产实践

不太适合的改动：重写整章说明、新增微服务、加 k8s 部署（路线见 [step-replan](notes/upgrade-journal/step-replan-2026-08-05.md)）。

---

## 📋 版本历史

| Version | Date | Highlights |
|---|---|---|
| **v3.41** | 2026-08-12 | Grafana 11.4 + Prom 2.55 升级；告警链路端到端跑通 |
| v3.40 | 2026-08-11 | M3/M4 关账 + `dev-e2e.sh` 回归基线（8/8 PASS）|
| v3.39 | 2026-08-11 | ch 11 日志笔记整理 |
| v3.37-3.38 | 2026-08-10 | ch 11 日志收集（filebeat + go-stash + ES + Kibana）|
| v3.35-3.36 | 2026-08-09 | ch 12 链路追踪（Jaeger + OTLP）|
| v3.33-3.34 | 2026-08-08 | ch 13 监控（Prometheus 12 target + Grafana 7 panel）|
| v3.26-v3.32 | 2026-08 | APISIX 实战 + dashboard 修复 |
| v3.24-v3.25 | 2026-08 | nginx `auth_request` 实战 |
| v3.17-v3.23 | 2026-08 | 跨服务 RPC + e2e 工作 doc + 完整下单流程文档 |
| v3.12 | 2026-08 | Kafka Brokers bug fix（`kafka:9092` → `127.0.0.1:9094`）|
| v3.0-v3.11 | 2026-08 | dev-up / dev-build / air 单文件统一 / go mod upgrade |

完整 git log：[github.com/zhanbinb/go-zero-looklook-new/commits/main](https://github.com/zhanbinb/go-zero-looklook-new/commits/main)

---

## 📜 License

[MIT](LICENSE) © 2026 zhanbinb

参考上游原版 [Mikaelemmmm/go-zero-looklook](https://github.com/Mikaelemmmm/go-zero-looklook) 的章节说明文档（[`doc/chinese/`](doc/chinese/)）。

---

## 🙏 致谢

- **[Mikaelemmmm/go-zero-looklook](https://github.com/Mikaelemmmm/go-zero-looklook)** — 业务拓扑与架构原版
- **[zeromicro/go-zero](https://github.com/zeromicro/go-zero)** — Go 微服务框架，作者 [kevingo](https://github.com/kevingo)
- **[cosmtrek/air](https://github.com/cosmtrek/air)** — Go 热重载工具
- **[grafana / prometheus / elastic / jaeger / kafka / redis / mysql](https://landscape.cncf.io/)** — 全套可观测性 + 数据基础设施
- **[kevinwan/go-stash](https://github.com/kevinwan/go-stash)** — logstash 的 Go 替代品

---

## 📈 当前状态

```
HEAD:    b68173e v3.41  (just pushed, 2026-08-12)
Branch:  main, clean working tree
服务:    11/11 ✅（usercenter-rpc 已恢复）
技术栈:  Go 1.24 + go-zero 1.10.2 + Prometheus v2.55.1 + Grafana 11.4.0
告警:    1 rule + 1 policy + 1 contact point, end-to-end verified
```

下一站：4d `pkg/errors` 全量迁移（用 `dev-e2e.sh` 回归），详见 [README §"已知未完成"](notes/upgrade-journal/README.md)。

---

*本 README 由 v3.41 落地时同步生成。配套 22 篇 step 笔记在 [notes/upgrade-journal/](notes/upgrade-journal/)，完整记录从 v3.0 到 v3.41 的演进过程。*
