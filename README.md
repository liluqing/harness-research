# Harness

> Agent 开发流程的组织系统——从"写提示词"到"像团队一样协作"。

## 这是什么

Harness 不是框架，不是工具，是一套让 AI Agent 执行软件开发任务的**流程规范 + 运行时系统**。

它解决的问题：给 Agent 一个需求，它不会乱猜、不会跳过关键步骤、该问人的时候问人、该自己定的时候自己定，产出可追溯、进度可续接。

## 快速开始

```bash
# 1. 在项目根目录创建上下文文件
cp dev-harness-skill/shared/project-context.md ./project.md
# 编辑 project.md，填写你的项目信息

# 2. 安装 Skill
ln -s $(pwd)/dev-harness-skill/skill.md ~/.hermes/skills/harness-dev-flow/SKILL.md
```

然后在飞书/终端对 Agent 说：**「我想做一个 XX 功能」**（进入 Phase 1）或 **「开发 XX 功能」**（进入 Phase 3）。

## 四阶段流程

```
用户需求 → Phase 1: 产品与原型 → Phase 2: 架构设计(可选) → Phase 3: Spec开发 → Phase 4: 集成测试
```

## 核心目录

```
harness-research/
├── README.md
├── dev-mode-flow.md                  # 开发模式 v2.1 完整流程
├── runtime-elements-design.md        # 运行时要素设计
├── cron-jobs-plan.md                 # Cron 持续优化方案
│
├── dev-harness-skill/                # ★ 可执行 Skill
│   ├── skill.md                      #   总入口
│   ├── phase-1-product-prototype/    #   产品与原型（✅）
│   ├── phase-2-architecture/         #   架构设计（🚧）
│   ├── phase-3-spec-dev/             #   Spec & 开发（✅）
│   ├── phase-4-integration-test/     #   集成测试（🚧）
│   └── shared/                       #   共享模板
│
├── scripts/                          # Cron 检测脚本
│   ├── check_feature_milestone.py
│   └── check_retro_gaps.py
│
└── harness-*.md                      # 方案探索文档（历史）
```

## 核心流程（一图胜千言）

```
PRD → ① Spec (决策树→概要→确认→详细) → ② 技术设计 → ③ 前端设计
                                                   ↓
                                         ④~⑧ 垂直切片 TDD 循环
                                         (每切片: 拆解→测试→RED→编码→GREEN)
                                                   ↓
                                          🏁 PR review + 验收
```

## 关键设计决策

| 决策 | 选择 | 原因 |
|------|------|------|
| 多 Agent vs 单 Agent | 单 Agent 换帽子 | 流程切换比多角色协调更可控 |
| TDD 真做 vs 表格 | **真做** | 测试代码先于实现，RED 必须真的跑过 |
| 瀑布 vs 垂直切片 | 垂直切片 | 逐端点交付，反馈快，上下文压力小 |
| Spec 一次写完 vs 决策树 | **先概要后详细** | 该 Agent 定的 Agent 定，该问的带选项问 |
| 所有决定问人 vs Agent 自主 | 量化边界 | 4 条分支 A 条件 + 5 条分支 B 条件 |

## 版本

v1.0 · 2026-06-07
