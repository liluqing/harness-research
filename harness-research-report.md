# Harness 研究报告：构建端到端 AI Agent 开发框架

> **背景：** 来源于微信公众号文章《一个文件让 AI Coding 效率翻倍：AGENTS.md 实践指南》（阿里云开发者社区，2026-05-06），文中推荐了 `harness-creator` 工具。
>
> **目标：** 研究什么是 Harness、Harness Creator 的原理，以及如何构建一个帮助 Agent 端到端完成开发任务的框架。
>
> **日期：** 2026-06-07
> **作者：** Hermes Agent (SOUL.md)

---

## 一、什么是 Harness？

**Harness 不是一套代码，而是一套给 AI Agent 用的"驾驶舱"**——包含规则、技能、流程文档、验证脚本。它让 Agent 打开项目就知道该干嘛、先干嘛、怎么验证。

> 核心思想来自 Anthropic 的 [Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps)

### Harness 解决的核心问题

在没有 Harness 的情况下，Agent 就像一个新同事，没人告诉它：

- 这个项目用的什么技术栈？
- 代码结构是什么样的？
- 有什么编码规约必须遵守？
- 怎么启动项目？怎么跑测试？
- 现在正在做什么？做到哪一步了？
- 什么算"做完了"？

Harness 就是把这些问题都写成文件放在项目里，让 Agent 打开就能理解。

---

## 二、调研发现的三个仓库

通过 GitHub 搜索 `harness-creator` 找到 44 个相关仓库，核心的三个如下：

### 1. fanlw0816/harness-creator（10⭐）— 最完整

**地址：** https://github.com/fanlw0816/harness-creator

**定位：** Claude Code 的元框架，一键生成定制的 `.claude/` harness 结构。

**特性：**
- GAN 启发的多 Agent 架构（Generator → Evaluator 分离）
- 领域模板系统（Web、Game、Data Science 等）
- Sprint Contract 机制
- 一键检测项目类型 + 自动生成
- 已克隆到本地 `/tmp/harness-creator/`

**与文章的匹配度：⭐⭐⭐⭐** — 文章提到的"生成 AGENTS.md、lint 脚本、Makefile、验证脚本"在这个 repo 里对应 hooks/ 目录中的脚本。

### 2. Arthurescc/harness-creator（5⭐）

**地址：** https://github.com/Arthurescc/harness-creator

**定位：** Codex Skill，用于设计安全的、分层的 Agent 运行时。

**特性：**
- "先建循环，再建编排"的渐进式方法
- "Deny-first"安全模型
- 四层成熟度模型（Tier 1-4）
- 侧重架构设计阶段而非代码生成

**与文章的匹配度：⭐⭐** — 更偏向 Codex 生态和 Agent 运行时设计，不直接生成 AGENTS.md。

### 3. ffy6511/harness-creator-skill（2⭐）

**地址：** https://github.com/ffy6511/harness-creator-skill

**定位：** walkinglabs/learn-harness-engineering 课程的改进版，专注 Spec-driven 开发。

**特性：**
- 两种模式：已有仓库模式 + Greenfield 模式
- specs/ 与 docs/ 分离
- 五子系统框架（Instructions、State、Verification、Scope、Lifecycle）
- 内置 detect-harness.sh 和 scaffold-greenfield.sh 脚本
- 模板驱动的 AGENTS.md 脚手架

**与文章的匹配度：⭐⭐⭐** — 概念上最贴近文章的"五子系统"理论，但星数少、更新不多。

### 原始来源

所有三个仓库的设计都基于同一篇文章：
- Anthropic 官方博客：[Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps)
- walkinglabs/learn-harness-engineering 课程（已下线或不再维护）

---

## 三、Harness 的核心架构

### 3.1 三层 Agent 架构（GAN 启发）

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Planner   │ ──► │  Generator  │ ──► │  Evaluator  │
│  (决策层)    │     │  (执行层)    │     │  (评估层)    │
└─────────────┘     └──────┬──────┘     └─────────────┘
                           │
                    spawns 领域 Specialist
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
        ┌──────────┐ ┌──────────┐ ┌──────────┐
        │ frontend │ │   api    │ │ database │
        │   -dev   │ │   -dev   │ │   -dev   │
        └──────────┘ └──────────┘ └──────────┘
```

| 层级 | Agent | 职责 |
|------|-------|------|
| **决策层** | Planner, architect-lead | 产品和架构决策 |
| **执行层** | Generator, domain-dev | 实现功能（可委托） |
| **评估层** | Evaluator | 测试和评分 |

**为什么必须分离？** 模型无法可靠地评估自己的工作——会把平庸输出称为"完成"、跳过边缘情况、遗漏集成问题。分离生成和评估是核心原则。

### 3.2 五子系统框架

| 子系统 | 作用 | 对应文件 |
|--------|------|----------|
| **Instructions** | 告诉 Agent 项目是什么、规矩是什么 | AGENTS.md、CLAUDE.md |
| **State** | 告诉 Agent 现在干到哪了 | specs/active/、progress.md、feature_list.json |
| **Verification** | 让 Agent 能自己验证 | scripts/、hooks/、Makefile |
| **Scope** | 防止 Agent 跑偏 | Sprint Contract、phase 边界 |
| **Lifecycle** | 让 Agent 会话能接上 | start/、checkpoint/、resume/ skills |

### 3.3 生成的目录结构

```
<项目>/
├── AGENTS.md                    # 给 Agent 的地图（精简概述）
├── CLAUDE.md -> AGENTS.md       # Claude Code 兼容软链接
│
├── .claude/                     # Claude Code 专属配置
│   ├── agents/                  # 各 Agent 的角色定义
│   │   ├── planner.md
│   │   ├── generator.md
│   │   ├── evaluator.md
│   │   ├── architect-lead.md
│   │   └── [domain]-dev.md
│   ├── skills/                  # Agent 技能
│   │   ├── start/
│   │   ├── checkpoint/
│   │   ├── resume/
│   │   └── sprint-contract/
│   ├── hooks/                   # 生命周期钩子
│   │   ├── pre-compact.sh
│   │   ├── session-start.sh
│   │   ├── session-stop.sh
│   │   ├── validate-commit.sh
│   │   └── validate-push.sh
│   ├── rules/                   # 安全规则
│   ├── evaluation/              # 评估模板
│   └── docs/                    # 架构文档
│
├── specs/                       # Spec 目录
│   ├── AGENTS.md                # specs 目录使用说明
│   ├── active/                  # 当前正在做的
│   ├── draft/                   # 待规划的
│   └── archive/                 # 已完成归档
│
├── docs/                        # 长期知识沉淀
│   ├── AGENTS.md                # docs 目录使用说明
│   ├── decisions/               # 设计决策记录
│   ├── features/                # 功能文档
│   └── lessons/                 # 经验教训
│
├── scripts/                     # 可执行脚本
│   ├── start-server.sh          # 一键启动
│   ├── run-tests.sh             # 跑测试
│   ├── lint-check.sh            # 代码规范检查
│   └── deploy.sh                # 部署
│
└── templates/                   # 模板文件
    ├── sprint-contract.md       # Sprint Contract 模板
    ├── evaluation-report.md     # 评估报告模板
    └── handoff-artifact.md      # 上下文交接模板
```

---

## 四、Generator Agent 的端到端工作流

根据 fanlw0816/harness-creator 中 `generator.md` 的定义：

```
① 读 spec → 提议 sprint contract
② 与 Evaluator + architect-lead 协商"完成"标准
③ 识别需要哪些领域 Specialist
④ 委托给 Specialist 并行干活（或自己实现）
⑤ 整合各 Specialist 输出
⑥ 自检是否达成 contract
⑦ 交给 Evaluator 评分
⑧ 根据反馈迭代或继续下一个
```

**关键设计细节：**

### Sprint Contract 生命周期

```
1. PROPOSE     Generator 提议 contract（含 specialist 分配）
      │
      ▼
2. REVIEW      architect-lead 审核架构
                Evaluator 审核可测试性
      │
      ▼
3. NEGOTIATE   往返协商直到达成一致
      │
      ▼
4. APPROVE     所有方签字确认
      │
      ▼
5. IMPLEMENT   Generator 协调 specialists
      │
      ▼
6. EVALUATE    Evaluator 按 contract 评分
      │
      ▼
7. ITERATE     不通过 → 修复问题，重新评估
```

### Specialist 委托规则

- **Contract Required**：没有已批准的 sprint contract 不能委托
- **Clear Task**：提供具体任务、范围和约束
- **Single Domain**：每个 Specialist 只干一个领域
- **Integration**：Generator 负责整合所有 Specialist 的输出
- **Quality Gate**：Specialist 输出必须通过领域质量检查

---

## 五、如何从头建一个 Harness

### Phase 1：AGENTS.md — Agent 的地图

项目根目录放一份约 200 行的精简概览，包含：

- 技术栈（Spring Boot + React 等）
- 仓库结构（server/、web/、docs/ 等）
- 硬性规则（异常处理、分层约束等）
- 如何启动、测试、部署
- 文档和参考项目的路径

**原则：地图，不是手册。详细内容放链接。**

### Phase 2：验证脚本 — 让 Agent 能自测

```bash
scripts/
├── start-server.sh     # 一键启动
├── run-tests.sh        # 跑测试
├── lint-check.sh       # 代码规范检查
└── deploy.sh           # 部署
```

### Phase 3：Spec 目录 — 当前进度

```
specs/AGENTS.md    ← 告诉 Agent specs 目录的用法
specs/active/      ← 当前 sprint 的 spec
specs/draft/       ← 待规划的
specs/archive/     ← 已完成归档
```

### Phase 4：评估体系

```
evaluation/
├── criteria/       ← 各类评估标准
└── templates/      ← 评估报告模板
```

### Phase 5：技能和钩子

```
skills/start/       ← 新会话引导
skills/checkpoint/  ← 保存进度
skills/resume/      ← 恢复上下文
hooks/              ← 生命周期钩子
```

---

## 六、关键原则

1. **Generator-Evaluator 分离**：写和审绝不能是同一个 Agent
2. **Sprint Contract First**：开工前先签"合同"，明确验收标准
3. **Domain Specialists**：Generator 委托 Specialist 干活，而不是自己硬干
4. **Context Reset**：长时间任务通过 handoff artifact 做上下文交接
5. **Concrete Criteria**：把主观判断变成可评分的标准
6. **地图不是手册**：AGENTS.md 约 200 行，详细内容放链接
7. **循环优先于编排**：先让最基本的循环跑通，再加多 Agent 协作
8. **渐进式积累**：不需要一步到位，从 bad case 驱动迭代

---

## 七、参考资源

- [Anthropic: Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps)
- [GitHub: fanlw0816/harness-creator](https://github.com/fanlw0816/harness-creator)
- [GitHub: Arthurescc/harness-creator](https://github.com/Arthurescc/harness-creator)
- [GitHub: ffy6511/harness-creator-skill](https://github.com/ffy6511/harness-creator-skill)
- [GitHub: walkinglabs/learn-harness-engineering](https://github.com/walkinglabs/learn-harness-engineering)（原始课程）
- 微信公众号文章：一个文件让 AI Coding 效率翻倍：AGENTS.md 实践指南（2026-05-06）
- OpenAI Harness Engineering 四大原则

---

## 八、附录：已克隆到本地的代码

```bash
/tmp/harness-creator/     ← fanlw0816/harness-creator（已完整克隆）
```

包含：
- `SKILL.md` — 完整的 Harness Creator Skill 定义（9110 字节）
- `references/` — 核心 Agent 定义、技能、钩子、评估体系
- `domain-templates/` — 领域模板（Web、Game、Data Science）
- `docs/` — 融合架构设计文档
- `tests/` — 测试脚本

相关文件也在本地 Hermes 技能目录：
- `~/.hermes/skills/devops/clash-verge/` — Clash Verge 代理管理技能
