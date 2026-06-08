---
name: harness-dev-flow
description: Harness 开发流程——从 PRD 到可运行代码的完整 Agent 执行系统。触发条件：用户提出开发需求时自动加载。**这是 Harness v1 的规范 Skill，关联目录 ~/docs/harness-research/harness-v1/。**
version: 1.0.0
tags: [harness, development, flow, tdd]
triggers:
  - 开发
  - 实现.*功能
  - 帮我做
  - 开始开发
  - 继续开发
---

# Harness 开发流程 Skill

当用户提出开发需求时，加载此 Skill。你是 Harness 开发流程的执行者，遵循以下规则。

## 〇、核心铁律（⚠️ 曾踩坑）

### 文档更新纪律

> **Markdown 是最终产出，HTML 只是沟通视图。**
>
> 修改流程/方案时，先更新 `.md` 文档，再更新 HTML。不要在 HTML 上迭代半天然后挑着同步回 md——必然遗漏。
>
> 教训：v2.1 更新时在 HTML 里加了优化策略但忘了同步到 md，用户指出后才补。此后所有改动必须 md 优先。

### 代码块换行

`patch` 工具的 `old_string` / `new_string` 中包含 code block 内容时，换行符可能被转义为 `\n`。修复方法见 `references/patch-tool-workaround.md`。

---

## 一、启动流程

### 1.1 判断模式

用户输入 → 判断是「新功能」还是「断点续接」：

- **新功能**：用户说「开发 XXX」「实现 XXX 功能」→ 从阶段 ① 开始
- **断点续接**：用户说「继续开发 XXX」「接着做 XXX」→ 读状态文件，从断点继续

### 1.2 加载上下文

开始任何工作前，按顺序加载：

```
1. 读 project.md（项目根目录）—— 了解技术栈、命名约定、代码组织
2. 读 ~/docs/harness-research/dev-mode-flow.md —— 完整流程定义
3. 如果有 PRD 文档 —— 读取 PRD
```

如果 project.md 不存在：提醒用户「请先在项目根目录创建 project.md，模板在 ~/docs/harness-research/harness-v1/templates/project-context.md」

---

## 二、执行阶段 ①：Spec 生成（决策树）

### 2.1 决策树流程

```
STEP 1 — 读取 PRD + project.md，列出所有待决策点
STEP 2 — 对每个决策点，按「决策边界规则」分类
STEP 3 — 输出 Spec 概要（做什么 + 核心流程 + Agent 已定 + 需用户定）
STEP 4 — 用户确认概要
STEP 5 — 展开详细 Spec → 写入 specs/<功能名>-spec.md
```

### 2.2 决策边界规则

对每个决策点，依次判断：

**走分支 A（Agent 自己定）—— 满足任一条件：**

| 条件 | 示例 |
|------|------|
| project.md 中有明确约定 | 表名单数、API 前缀 `/api/v1` |
| 行业有广泛接受的标准做法 | RESTful 规范、Bean Validation |
| 决策做错后改动成本低（≤ 50 行代码，不涉及数据迁移） | 变量命名、方法拆分 |

Agent 自己定的决策，在概要中用一句话顺带告知用户，如：
> **Agent 已定：** 表名用单数 user，跟项目已有表命名一致；API 路径 /api/v1/users。

**走分支 B（必须问用户）—— 满足任一条件：**

| 条件 | 示例 |
|------|------|
| 影响用户数据或业务流程 | 删除策略、权限模型、状态流转 |
| 影响交付范围 | 这版做不做某个子功能 |
| 引入新依赖或架构变化 | 选 Redis 还是本地缓存 |
| 和外部系统交互 | 第三方 API 调用方式 |
| PRD 完全没提且 Agent 无法推断 | 特殊业务规则 |

走分支 B 时，必须给出 2~3 个选项 + 建议：
> **需要你定：**
> 1. 删除策略 → A. 软删除 B. 硬删除+归档 C. 仅解关联。建议 A，数据可追溯。

**约束：**
- 每次不超过 3 个决策点
- 超过 3 个说明 PRD 不够清晰，告知用户补充 PRD
- 不说「要不要做 XX」，说「XX 有 A/B/C，建议 A，因为...」

### 2.3 Spec 概要格式

```markdown
【Spec 概要】<功能名>

**做什么：** 一句话描述

**核心流程：** 2~3 句话描述主流程

**Agent 已定：** （分支 A 的决策，一句话告知）

**需要你定（N 个）：** （分支 B 的决策，带选项 + 建议）
```

发送概要给用户 → 等确认 → 展开详细 Spec。

### 2.4 详细 Spec

使用模板：`~/docs/harness-research/harness-v1/templates/spec.md`

写入：`specs/<功能名>-spec.md`

---

## 三、执行阶段 ②：技术设计

输入：已确认的 Spec
模板：`~/docs/harness-research/harness-v1/templates/design.md`

产出 `docs/design/<功能名>-design.md`。

写完后附带说明发给用户「扫一眼」（推荐，非强制）。

**设计约束：**
- 不写具体代码，只描述结构和约束
- API 字段定义、Entity 字段定义、DB 字段定义保持一致
- 遇到不确定的业务规则，优先问用户

---

## 四、执行阶段 ③：前端设计（条件性）

仅当满足以下全部条件时触发：
- 功能有前端界面
- 且满足以下至少一项：多步状态流转 / ≥3 个交互分支 / 实时协作 / 复杂表单校验

模板：`~/docs/harness-research/harness-v1/templates/ui.md`

---

## 五、执行阶段 ④~⑧：垂直切片 TDD 循环

### 5.1 切片规划

将 API 端点拆为独立切片，按依赖排序（先创建后查询）。

示例：
```
切片 A: POST /api/v1/users (创建)
切片 B: GET /api/v1/users/{id} (查询)
切片 C: PUT /api/v1/users/{id} (更新)
```

### 5.2 每切片执行流程

```
④ 任务拆解（模板：templates/slice-task.md）
⑤ 写测试代码 → 产出 src/test/.../*Test.java
⑥ 跑测试 → 确认全红（RED）← 关键仪式！
⑦ 编码实现 → 最小实现让测试变绿
⑧ 编译 + 跑测试 → 全绿（GREEN）
→ 通报用户：「切片 X 完成 ✅，开始切片 Y」
```

**TDD 铁律：**
- 必须先跑出 RED 再写实现
- 如果 RED 失败原因不是「代码未实现」而是测试本身写错 → 先修测试
- GREEN 不通过时改代码，不改测试

### 5.3 编码中遇到设计冲突

1. 先看技术设计文档——它是约定
2. 如果设计确实有问题 → **更新设计文档再继续编码**（不要悄悄偏离）
3. 如果是实现细节选择（不影响设计文档）→ Agent 自主决定
4. 如果是影响设计的冲突且 Agent 无法判断 → 升级给用户 `[偏离 · 类型]`

---

## 六、状态跟踪协议

### 6.1 状态文件

每开始一个新功能，在 `~/.hermes/metrics/state/<项目名>/` 下创建 `<功能名>.json`。

模板：`~/docs/harness-research/harness-v1/templates/state.json`

### 6.2 更新时机

| 事件 | 更新内容 |
|------|------|
| Spec 完成 | phases.spec = "completed"，记录 artifacts.spec |
| 设计完成 | phases.design = "completed" |
| 切片开始 | slices.<id>.status = "in_progress"，记录 started |
| 切片完成 | slices.<id>.status = "completed"，记录 completed |
| 全部切片完成 | status = "completed" |

### 6.3 指标记录

编码过程中实时记录：
- 偏离事件 → 写到 metrics.deviations 数组
- Spec/设计确认轮数 → 更新 metrics.spec_rounds / design_fixes
- 切片耗时 → 更新 slices.<id>.duration

功能交付后，汇总写入 `~/.hermes/metrics/summary.json`。

### 6.4 断点续接

用户说「继续开发 XXX」时：
1. 读 `~/.hermes/metrics/state/<项目>/<功能名>.json`
2. 找到 current_phase
3. 读已有文档和源码
4. 从断点继续

---

## 七、最终交付

全部切片完成后：
1. 运行集成验证（可选）
2. 生成 Retro 回顾摘要 → 写入 `~/.hermes/metrics/retros/<项目>/<功能名>.md`
3. 提交 PR → 发给用户 review

---

## 八、关键原则

1. **先概要后详细** — Spec 阶段必须走 5 步决策树，不能跳过概要直接写详细 Spec
2. **文档是契约** — 设计文档定了就不要悄悄偏离，要改先更新文档
3. **TDD 仪式** — RED 必须真的跑过，不能跳过
4. **状态不丢** — 每完成一个阶段/切片立即更新状态文件
5. **该问问、该定定** — 按决策边界规则判断，不要所有事都问，也不要所有事都自己定

---

## 九、模板引用

所有模板在 `~/docs/harness-research/harness-v1/templates/`：

| 模板 | 用途 |
|------|------|
| `project-context.md` | 项目上下文（首次使用 Harness 时填写） |
| `spec.md` | Spec 文档 |
| `design.md` | 技术设计文档 |
| `ui.md` | 前端设计文档 |
| `test-case.md` | 测试用例 |
| `slice-task.md` | 切片任务卡片 |
| `state.json` | 状态文件 |

---

## 十、工具使用注意事项

### Patch 工具的多行代码块陷阱

使用 `patch` 工具替换包含 markdown 代码块（```）的多行内容时，换行符可能被转义为字面量 `\n`。遇到此类场景：
- 优先用 `write_file` 写完整文件
- 或用 `execute_code` 调用 `read_file` + `write_file` 做字符串替换

详见 `references/patch-newline-escape-pitfall.md`。
