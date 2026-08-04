# go-zero-looklook 升级日志（upgrade-journal）

> 把 Mikaelemmmm/go-zero-looklook 从 2022-2023 的 v1 状态，升级到 2026 年的现代 Go 微服务栈。
> 一边升级，一边学习。

## 项目结构

```
go-zero-looklook-study/
├── go-zero-looklook/            # v1 原项目（git clone 下来的基线）
└── notes/upgrade-journal/       # 本目录：升级过程的所有记录
    ├── README.md                # 本文件
    ├── step-00-v1-baseline.md   # v1 现状摸底
    ├── step-01-env-setup.md     # 开发环境搭建（Apple Silicon 适配）
    ├── step-02-toolchain.md     # [待做] modd → air + 基础镜像升级
    ├── step-03-usercenter.md    # [待做] 单服务 build 跑通
    ├── step-04a-go-zero-1.9.md  # [待做] go-zero 1.7.3 → 1.9
    ├── step-04b-redis-v9.md     # [待做] go-redis v8 → v9
    ├── step-04c-jwt-v5.md       # [待做] golang-jwt v4 → v5
    ├── step-04d-errors.md       # [待做] pkg/errors → 标准库
    ├── step-05-all-services.md  # [待做] 推广到 5 个服务
    ├── compare/                 # 升级前后代码对比
    └── patches/                 # 升级用的 diff / 修复文件
```

## 升级路线图（5 步最小可用）

```
Step 0  v1 现状摸底                          ← 当前
Step 1  开发环境搭建（docker-compose）        ← 当前
Step 2  升级开发工具链（modd → air / 基础镜像）
Step 3  单服务（usercenter）build 跑通
Step 4  升级 4 个过期依赖（go-zero / redis / jwt / errors）
Step 5  推广到全部 5 个服务 + 端到端验证
```

## 当前状态

- ✅ Step 0 完成：v1 baseline 已记录
- 🚧 Step 1 进行中：docker-compose 启动修复中
- ⏳ Step 2-5 待启动

## 工作约定

- 所有"动手"操作在 `go-zero-looklook-new/` 目录
- v1 参照读 `go-zero-looklook-study/go-zero-looklook/`（只读，不动）
- 升级决策记录在 `compare/` 和 `patches/` 目录
- 每篇 step 笔记固定格式：目标 / 改动文件 / 关键 diff / 踩坑 / 验证 / 时长
