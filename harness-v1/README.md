# Harness v1

> Agent 开发流程的运行时实现。人定义需求，Agent 执行流程——从 PRD 到可运行代码。

## 这是什么

Harness 不是框架，是一套让 Agent 像开发团队一样工作的**组织系统**。它包含：

- **流程定义** — Agent 接到需求后按什么步骤走
- **Skill** — Agent 如何「知道」并「遵守」这套流程
- **模板** — 各阶段产出的文档骨架
- **规则** — 什么决策 Agent 自己定，什么必须问人
- **状态** — 跨会话的进度记录，断点续接

## 目录

```
harness-v1/
├── README.md                      # 本文件
├── skill-harness-dev-flow.md      # Skill 定义（流程注入 + 决策边界 + 触发逻辑）
├── templates/
│   ├── project-context.md         # 项目上下文（Agent 决策时的参考）
│   ├── spec.md                    # Spec 文档模板
│   ├── design.md                  # 技术设计文档模板
│   ├── ui.md                      # 前端设计文档模板
│   ├── test-case.md               # 测试用例模板
│   ├── slice-task.md              # 切片任务卡片模板
│   └── state.json                 # 跨会话状态文件模板
├── rules/
│   └── decision-boundary.md       # Spec 决策树判断标准
└── scripts/ -> ../scripts/        # Cron 检测脚本
```

## 依赖的父级文档

本目录是 Harness 的「可执行层」。设计原理和完整流程描述在父目录：

| 文档 | 说明 |
|------|------|
| `../dev-mode-flow.md` | 开发模式 v2.1 完整流程定义 |
| `../runtime-elements-design.md` | 6 个运行时要素的设计原理 |
| `../cron-jobs-plan.md` | 持续优化 Cron 任务方案 |

## 使用方式

### 1. 首次使用：初始化项目上下文

在项目根目录放一份 `project.md`（基于 `templates/project-context.md` 填写）。

### 2. 安装 Skill

```bash
# 将 skill 链接到 Hermes 技能目录
ln -s /home/llq-claw/docs/harness-research/harness-v1/skill-harness-dev-flow.md \
      ~/.hermes/skills/harness-dev-flow/SKILL.md
```

### 3. 触发开发

在飞书或其他渠道对 Agent 说：

> 开发用户管理功能

或发送 PRD 文档 + 「开发这个」。

Agent 自动加载 Skill，按流程执行。

### 4. 断点续接

> 继续开发用户管理

Agent 读状态文件，从上次中断的位置继续。

## 版本

v1.0 · 2026-06-07
