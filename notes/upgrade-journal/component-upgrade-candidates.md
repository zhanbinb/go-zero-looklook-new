# 组件升级候选清单（Component Upgrade Candidates Register）

> 日期：2026-08-05 开始  
> 目的：边做边观察 go-zero-looklook 教程里的"旧组件"在 2026 年是否值得换成现代等价物  
> 用法：每接触到一个新组件，先看这里有没有"候选"，没的话就再加一行  
> 关联：`step-replan-2026-08-05.md` 第 5 节（详细版）

## 表格（按接触时间顺序排列）

### ② 网关 ch 2
| 候选 | 适用度 | 决策 | 备注 |
|------|--------|------|------|
| **nginx + auth_request** | ⭐⭐⭐⭐ | 当前 | 现成 `deploy/nginx/conf.d/looklook-gateway.conf` |
| APISIX | ⭐⭐⭐⭐⭐ | 评估中 | Apache 顶级项目，dashboard + 100+ 插件，go-zero 生态友好 |
| Kong | ⭐⭐⭐ | 不优先 | OpenResty 调试链不顺 |
| Higress | ⭐⭐⭐ | 不优先 | 阿里体系 |
| Traefik | ⭐⭐⭐⭐ | 不优先 | k8s 友好，单机可省事 |

### ⑤ 队列 ch 8 — 延迟/定时
| 候选 | 适用度 | 决策 | 备注 |
|------|--------|------|------|
| **asynq**（现）| ⭐⭐⭐⭐ | 当前 | Redis 后端，简单 |
| River | ⭐⭐⭐⭐ | 备选 | Postgres 后端，同库搞定，类型安全 |
| Machinery | ⭐⭐ | 不优先 | 老牌，代码复杂 |

### ⑧ 队列 ch 8 — 消息流
| 候选 | 适用度 | 决策 | 备注 |
|------|--------|------|------|
| **go-queue kq**（现）| ⭐⭐⭐ | 当前 | kafka 包装，go-zero 自家 |
| kafka client 原生 | ⭐⭐ | 不优先 | 失去 go-zero 集成收益 |
| NATS / Redis Streams | ⭐⭐ | 不优先 | 量小没必要 |

### ⑪ 日志 ch 11
| 候选 | 适用度 | 决策 | 备注 |
|------|--------|------|------|
| **ELK + filebeat + go-stash**（现）| ⭐⭐⭐ | 当前 | 经典但重 |
| Loki + Promtail + Grafana | ⭐⭐⭐⭐ | 备选 | 与 grafana 共栈，标签查询 |
| Vector + ES | ⭐⭐⭐ | 备选 | 单一 binary 替代 filebeat+go-stash |

### ⑫ 链路追踪 ch 12
| 候选 | 适用度 | 决策 | 备注 |
|------|--------|------|------|
| **jaeger**（现但 Telemetry 错配）| ⭐⭐⭐ | 改造 | go-zero 1.10 已不支持 jaeger 直连 |
| OpenTelemetry Collector → Jaeger/Tempo | ⭐⭐⭐⭐⭐ | **目标方案** | 厂商中立，主流 |
| SigNoz | ⭐⭐⭐⭐ | 不优先 | 单栈体验好，但与现有 prom/grafana 重叠 |

### ⑬ 服务监控 ch 13
| 候选 | 适用度 | 决策 | 备注 |
|------|--------|------|------|
| **Prometheus + Grafana**（现）| ⭐⭐⭐⭐⭐ | 当前 | go-zero 内置，最标准 |
| VictoriaMetrics | ⭐⭐⭐⭐ | 备选 | 协议兼容，存储压缩好 |
| Mimir | ⭐⭐⭐ | 不优先 | 重量级，超出本地规模需要 |

### ④-⑦ 业务框架层
| 候选 | 适用度 | 决策 | 备注 |
|------|--------|------|------|
| **go-zero**（现）| ⭐⭐⭐⭐⭐ | 当前 | 主框架 |
| Kratos / Cloudwego / Hertz | ⭐⭐ | 不切换 | 跨框架是大工程 |

## 接触时机（按 M1-M4 安排）

| Phase | 可能触动 | 关注 |
|-------|----------|------|
| M1    | 全部 5 服务 yaml | 看 Telemetry / Prometheus 字段是否合理 |
| M2    | 跨服务 RPC 配置 | 看 RPC 错误码、retry、timeout 配置 |
| M3    | 1 条 e2e 业务 | 看 kafka topic 是否合理 |
| ch 12 | Telemetry | **主要改造点**：上 OTel Collector |
| ch 11 | filebeat 配置 | 评估 Loki 替换 |
| ch 13 | prometheus.yml | 看 scrape target 与端口一致 |
| ch 2  | nginx | 评估 APISIX |

## 决策原则

1. **新组件必须有"具体痛点"驱动**——比如 ch 11 如果手工运维感到痛苦，再考虑 Loki
2. **学习价值 > 生产价值**——本期目的"学"，所以即使最终不上生产也可以试
3. **不必替换干净**——可以"挂两个"，比如保留 nginx + 旁边跑 APISIX 对比
4. **替换要先做 PoC**——任何大替换前先在 dev 单独跑一遍，再整合

## 排除项

- ❌ Spring Cloud / Dubbo 等 Java 栈（语言不同）
- ❌ 重型商业方案（consul+istio+envoy 这种）
- ❌ 单纯追求"新"的版本（go 1.24 暂不追 1.25，因为 go-zero 兼容性）
- ❌ 更换 RPC 协议（保持 gRPC，与生产对齐）

---

*创建于 2026-08-05，随着 M1-M4 推进实时更新*
