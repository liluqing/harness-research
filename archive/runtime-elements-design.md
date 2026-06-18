# Harness 运行时要素设计

> **定位：** 让 dev-mode-flow.md 从「流程描述」变成「Agent 可执行的系统」。
> **前置阅读：** `dev-mode-flow.md`、`cron-jobs-plan.md`

---

## 总览

```
┌─────────────────────────────────────────────────────────────┐
│                    Harness 运行时                            │
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────────┐ │
│  │ ① 流程   │  │ ② 项目   │  │ ③ 模板   │  │ ④ 决策     │ │
│  │   注入   │  │   上下文  │  │   库     │  │   边界     │ │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └──────┬──────┘ │
│       │             │             │               │         │
│  ┌────┴─────────────┴─────────────┴───────────────┴──────┐ │
│  │              ⑤ 状态跟踪（跨会话）                      │ │
│  └────────────────────────┬──────────────────────────────┘ │
│                           │                                 │
│  ┌────────────────────────┴──────────────────────────────┐ │
│  │              ⑥ 触发与入口                              │ │
│  └───────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## 要素 ①：流程注入 —— Agent 怎么「知道」并「遵守」流程

### 问题

流程文档写了 700 行，Agent 默认状态下不知道它存在。需要一种机制让 Agent 在执行开发任务时自动加载流程定义。

### 方案：Harness Skill

创建一个 Skill 文件 `harness-dev-flow`，作为流程的「可加载入口」。

**Skill 是什么：**
- Agent 启动时不会自动加载所有技能，只在识别到相关任务时按需加载
- Skill 文件包含：触发条件 + 核心指令 + 对详细文档的引用

**设计：**

```yaml
触发条件: 用户提出开发需求（"开发XX功能"、"实现XX"、"写XX接口"）
核心指令: 加载 dev-mode-flow.md 作为流程约束
         加载项目上下文（要素②）
         加载模板库（要素③）
         按决策边界（要素④）执行 Spec 阶段的决策树
```

**Agent 行为：**
- 收到开发需求 → 识别触发词 → 加载 skill → skill 指示加载 dev-mode-flow.md → Agent 按流程走
- 每个阶段开始时，Agent 从 dev-mode-flow.md 读取当前阶段的定义
- 阶段切换时更新状态文件（要素⑤）

### 产出

- `~/.hermes/skills/harness-dev-flow/SKILL.md` — Skill 入口
- `~/.hermes/skills/harness-dev-flow/references/` — 对 docs 的引用

---

## 要素 ②：项目上下文 —— Agent 决策时需要知道的项目信息

### 问题

Agent 在做 Spec 决策树的「分支 A：项目上下文可推导」判断时，需要知道项目的实际信息。否则所有决策都只能走「分支 B：问用户」。

### 方案：项目上下文文件

创建 `project.md`（或 `AGENTS.md` / `CLAUDE.md` 风格），由用户填写一次，Agent 每次执行开发流程时自动加载。

**内容结构：**

```markdown
# 项目上下文

## 基本信息
- 项目名
- 技术栈（语言/框架/构建工具/数据库）

## 代码组织
- 源码目录结构
- 包/模块命名约定
- API 路径前缀

## 数据库约定
- 表名：单数 or 复数
- 主键策略：自增 or UUID
- 时间字段：created_at / updated_at

## 代码风格
- 缩进、命名规范
- 包结构约定
- DTO/Entity/Repository 命名模式

## 测试
- 测试框架
- 测试文件位置约定
- 构建/测试命令

## 已有模块（Agent 可选读）
- 已有的 Entity / Service / Controller 列表
```

### 使用方式

- 项目根目录放置 `project.md`
- Agent 启动流程时第一步读此文件
- 决策树「分支 A」的判断基于此文件中的约定
- 用户新增约定时更新此文件

### 产出

- `project.md` 模板 → 放在 `~/docs/harness-research/templates/project-context-template.md`

---

## 要素 ③：模板库 —— 文档的可复用骨架

### 问题

dev-mode-flow.md 中各阶段的文档结构是内嵌在流程描述里的。Agent 每次需要从头推导文档格式，效率低且容易遗漏字段。

### 方案：独立模板文件

把 Spec、技术设计、前端设计等文档骨架提取为独立模板文件。

**模板清单：**

| 模板 | 位置 | 对应阶段 |
|------|------|:--:|
| Spec 模板 | `templates/spec-template.md` | ① |
| 技术设计模板 | `templates/design-template.md` | ② |
| 前端设计模板 | `templates/ui-template.md` | ③ |
| 测试用例模板 | `templates/test-case-template.md` | ⑤ |
| 切片任务卡片模板 | `templates/slice-task-template.md` | ④ |

### 使用方式

- Agent 进入某个阶段时，读取对应模板
- 按模板结构填充内容
- 模板中包含注释（`<!-- ... -->`）指导 Agent 哪些字段必填、哪些可选

### 产出

- `~/docs/harness-research/templates/` 目录下的 5 个模板文件

---

## 要素 ④：决策边界 —— Spec 决策树的可执行判断标准

### 问题

决策树「分支 A：项目上下文可推导」vs「分支 B：影响大/需求模糊」的边界目前靠 Agent 主观判断，不够稳定。

### 方案：量化判断标准

**分支判断矩阵：**

| 决策类型 | 示例 | 走哪条分支 | 决策标准 |
|----------|------|:--:|------|
| 命名约定 | 表名、API 路径、类名后缀 | A | 项目已有明确约定 → Agent 定 |
| 数据模型 | 字段类型、关系映射 | A（大部分） | ORM 已知 + 项目已有类似模型 → Agent 定 |
| 校验规则 | 字段长度、格式 | A | 通用规则（邮箱、手机号）→ Agent 定 |
| 业务规则 | 删除策略、状态流转、权限 | B | **影响用户数据或业务流程** → 问 |
| 范围决策 | 这版做不做某个子功能 | B | **影响交付范围** → 问 |
| 技术选型 | 缓存方案、消息队列 | B | **引入新依赖或架构变化** → 问 |
| 集成方式 | 第三方 API 调用方式 | B | **和外部系统交互** → 问 |

**Agent 自检清单（嵌入 Skill）：**

```
对每个待决策点，问自己三个问题：

1. 这个决策在项目上下文（project.md）中有明确约定吗？
   → 是 → 分支 A

2. 这个决策在行业里有广泛接受的标准做法吗？（如 RESTful 规范、命名约定）
   → 是 → 分支 A（可顺带告知用户）

3. 这个决策如果做错，需要改多少代码/数据？
   → 改 > 50 行代码 或 涉及数据迁移 → 分支 B
   → 改 ≤ 50 行代码 且 不涉及数据 → 分支 A（Agent 定，错了再改成本低）
```

### 产出

- 判断矩阵 + 自检清单 → 嵌入在 Harness Skill 中

---

## 要素 ⑤：状态跟踪 —— 跨会话进度记录和恢复

### 问题

一个功能的开发不会在一个会话内完成。Agent 需要知道「做到哪个切片了」「上次做到哪了」。

另外，Agent 每阶段产出后需要主动更新 `~/.hermes/metrics/summary.json` 供 cron 使用。

### 方案：轻量状态文件

**状态文件：** `~/.hermes/metrics/state/<项目名>/<功能名>.json`

**结构：**

```json
{
  "feature": "用户管理",
  "project": "xxx",
  "status": "in_progress",
  "current_phase": "slice_C",
  "phases": {
    "spec": "completed",
    "design": "completed",
    "ui_design": "skipped",
    "slices": {
      "slice_A": {"endpoint": "POST /users", "status": "completed", "started": "...", "completed": "..."},
      "slice_B": {"endpoint": "GET /users/{id}", "status": "completed", "started": "...", "completed": "..."},
      "slice_C": {"endpoint": "PUT /users/{id}", "status": "in_progress", "started": "...", "completed": null},
      "slice_D": {"endpoint": "DELETE /users/{id}", "status": "pending"},
      "slice_E": {"endpoint": "GET /users", "status": "pending"}
    }
  },
  "artifacts": {
    "spec": "specs/用户管理-spec.md",
    "design": "docs/design/用户管理-design.md",
    "pr_branch": "feature/user-management"
  },
  "metrics": {
    "spec_rounds": 1,
    "design_fixes": 0,
    "deviations": []
  },
  "session_ids": ["20260607_xxx", "20260608_yyy"]
}
```

### 使用方式

- **Agent 每完成一个阶段/切片** → 更新状态文件
- **新会话开始** → Agent 读状态文件，看是否有未完成的功能，自动续上
- **用户说「继续做用户管理」** → Agent 读状态文件，找到 `current_phase`，从断点继续
- **功能交付后** → 状态文件归档到 `completed/`，更新 summary.json

### 产出

- 状态文件模板 → `~/docs/harness-research/templates/state-template.json`

---

## 要素 ⑥：触发与入口 —— 开发流程怎么启动

### 问题

Agent 需要明确的入口来识别「现在是开发模式」。

### 方案：自然语言触发 + 显式指令

**触发词（任一即可）：**

- 「开发 [功能名]」
- 「实现 [功能名] 功能」
- 「帮我做 [功能名]」
- 「开始开发 [功能名]」
- 用户发送 PRD 文档链接 +「开发这个」

**Agent 响应流程：**

```
1. 识别触发 → 加载 harness-dev-flow skill
2. 加载项目上下文（project.md）
3. 读取 dev-mode-flow.md 流程定义
4. 如果存在 PRD：
   → 进入阶段 ① Spec 决策树
5. 如果无 PRD：
   → 「请提供 PRD，或说一下需求要点」
6. 如果是续接（状态文件存在且 status=in_progress）：
   → 读取状态文件 → 从断点继续
```

### 断点续接

```
用户：「继续开发用户管理」
Agent：
  1. 读 ~/.hermes/metrics/state/<项目>/用户管理.json
  2. 发现 current_phase = "slice_C" (PUT /users)
  3. 加载相关文档 + 源码
  4. 从切片 C 的编码阶段继续
```

### 产出

- Skill 的触发逻辑 + 断点续接逻辑 → 嵌入在 Harness Skill 中

---

## 落地清单

| # | 要素 | 产出 | 类型 |
|:-:|------|------|:--:|
| ① | 流程注入 | `~/.hermes/skills/harness-dev-flow/SKILL.md` | Skill |
| ② | 项目上下文 | `~/docs/harness-research/templates/project-context-template.md` | 模板 |
| ③ | 模板库 | `~/docs/harness-research/templates/{spec,design,ui,test,slice}-template.md` | 模板 x5 |
| ④ | 决策边界 | 嵌入 Skill 的判断矩阵 + 自检清单 | 文档 |
| ⑤ | 状态跟踪 | `~/docs/harness-research/templates/state-template.json` | 模板 |
| ⑥ | 触发与入口 | 嵌入 Skill 的触发逻辑 + 断点续接 | 逻辑 |
