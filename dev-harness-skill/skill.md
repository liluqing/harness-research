---
name: harness-dev-flow
description: Harness 开发流程——从需求到交付的 4 阶段完整 Agent 执行系统。
version: 2.0.0
tags: [harness, development, flow, tdd, product, prototype]
triggers:
  - 开发
  - 实现.*功能
  - 帮我做
  - 开始开发
  - 继续开发
  - 需求分析
  - PRD
  - 原型
  - 集成测试
---

# Harness 完整开发流程 Skill

当用户提出软件开发相关需求时，加载此 Skill。你是 Harness 流程的执行者。

## 四阶段总览

```
用户原始需求
    ↓
Phase 1: 产品与原型  →  产出 PRD + 可选原型 HTML
    ↓
Phase 2: 架构设计（可选）→  产出架构文档 + 任务拆解
    ↓
Phase 3: Spec & 开发  →  逐任务 Spec 分析 + TDD 开发
    ↓
Phase 4: 集成测试     →  启动服务 + 调接口 + 验证报告
    ↓
交付
```

## 阶段路由

根据用户输入判断进入哪个阶段：

| 用户输入 | 进入阶段 | 操作 |
|------|:--:|------|
| 「我想做一个 XX」「帮我分析 XX 需求」 | Phase 1 | 加载 `phase-1-product-prototype/flow.md` |
| 「XX 功能已确认，设计下架构」 | Phase 2 | 加载 `phase-2-architecture/README.md` |
| 「开发 XX」「实现 XX 接口」 | Phase 3 | 加载 `phase-3-spec-dev/flow.md` + `rules/decision-boundary.md` |
| 「做集成测试」「验证 XX」 | Phase 4 | 加载 `phase-4-integration-test/README.md` |
| 「继续做 XX」 | 断点续接 | 读状态文件 → 从断点继续 |

## 共享资源

所有阶段共享：

| 资源 | 位置 | 用途 |
|------|------|------|
| 项目上下文 | `shared/project-context.md` | Agent 决策时的参考 |
| 状态文件 | `shared/state.json`（模板） | 跨会话进度记录 |
| 决策边界 | `phase-3-spec-dev/rules/decision-boundary.md` | Phase 1 & 3 的决策树标准 |

## 关键原则

1. **Phase 1 先于 Phase 3** — 没有 PRD 不写 Spec
2. **Phase 2 可选但有价值** — 多模块项目建议走，简单 CRUD 可跳过
3. **先概要后详细** — Phase 1 的 PRD 和 Phase 3 的 Spec 都先出概要确认再展开
4. **该问问、该定定** — 产品层（Phase 1）和 Spec 层（Phase 3）各有一套决策边界
5. **状态不丢** — 每完成阶段/切片立即更新状态文件
