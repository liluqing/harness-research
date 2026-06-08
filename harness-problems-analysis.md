# AI 编码实战问题 & Harness 解决方案分析

> **说明：** 本文档列出 AI 在端到端编码过程中遇到的实际问题，
> 以及如何通过构建 Harness（而非靠模型本身）来解决这些问题。
>
> 这份是初版清单，后续根据讨论持续更新。

---

## 问题总览

| # | 问题 | 严重程度 | 涉及阶段 |
|---|------|---------|---------|
| 1 | 上下文断裂 | 🔴 致命 | 全流程 |
| 2 | 不知道项目规矩 | 🔴 致命 | 编码 |
| 3 | 无法自启动和验证 | 🔴 致命 | 验证 |
| 4 | 质量无法保证（自审不可靠） | 🟠 严重 | 编码→验证 |
| 5 | Scope 蔓延 | 🟠 严重 | 编码 |
| 6 | 无进度追踪 | 🟡 中等 | 全流程 |
| 7 | 多模块/多文件协作困难 | 🟡 中等 | 编码 |
| 8 | 私域组件/内部库不识 | 🟡 中等 | 编码 |
| 9 | 环境配置不一致 | 🟡 中等 | 启动→验证 |
| 10 | 记忆与连续性 | 🟠 严重 | 全流程 |

---

## 详细分析

### 问题 1：上下文断裂 🔴

**表现：**
- Agent 每次新会话都是白纸一张，不知道项目背景
- 不知道当前正在做什么、做到哪一步了
- 之前做过的架构决策、排除的方案，下次又重来一遍

**Harness 解法：**

```
AGENTS.md (项目地图)
  ├─ 技术栈、仓库结构、核心模块说明
  └─ 文档索引 → 详细架构文档

specs/active/ (当前状态)
  ├─ 当前 sprint 的 spec → "现在在做什么"
  └─ 已完成 checkpoint → "做到哪了"

skills/resume/ (恢复技能)
  └─ 读取上次会话的 handoff artifact → "上次说到哪了"
```

**核心思路：** 不是让模型记住一切，而是把状态写在文件里，每次醒来先读文件。

---

### 问题 2：不知道项目规矩 🔴

**表现：**
- 异常直接 `throw new RuntimeException()` 而不是项目的 `BusinessException`
- 手动 `new Response(code, data)` 包装返回值，但框架已经统一封装了
- Controller 直接注入 Repository 跳过 Service 层
- 命名风格不一致

**Harness 解法：**

```
AGENTS.md 中写硬性规则：
  ## 必须遵守的编码规约
  - 异常必须通过 BusinessException 抛出
  - 响应体由框架统一包装，禁止手动构造
  - Controller 只能调用 Service，不能直接注入 Repository
  - 新增 API 必须有对应的单元测试

rules/ 目录放详细规则文档：
  rules/coding-standards.md
  rules/exception-handling.md
  rules/api-design.md

hooks/validate-commit.sh 自动检查：
  └─ 提交前扫描代码是否符合规约，不符合则拒绝提交
```

**核心思路：** 把编码规约从人的脑子里搬到 AGENTS.md 里，再通过 git hooks 强制执行。

---

### 问题 3：无法自启动和验证 🔴

**表现：**
- Agent 改完代码，不知道怎么启动项目来验证
- 启动命令散落在各种文档和聊天记录里
- 本地环境配置方式不统一
- Agent 只能改代码，不能验证，闭环断裂

**Harness 解法：**

```
scripts/start-server.sh     ← 一键启动（JDK检测 + 端口检查 + 健康检查轮询）
scripts/run-tests.sh        ← 跑测试（单元测试 + 集成测试）
scripts/lint-check.sh       ← 代码规范检查
scripts/check-health.sh     ← 健康检查

AGENTS.md 中写明：
  ## 启动方式
  1. 确保 ~/.<project>_env 存在（或参考 docs/development.md）
  2. ./scripts/start-server.sh
  3. ./scripts/run-tests.sh

  ## 验证步骤
  改完代码后依次执行：
  1. ./scripts/lint-check.sh    # 检查规范
  2. ./scripts/run-tests.sh     # 跑测试
  3. 启动服务 → curl 验证接口   # 端到端验证
```

**核心思路：** 封装一键脚本，Agent 改完代码就能自己跑验证。这是让 Agent 从"半自动"变"全自动"的关键。

---

### 问题 4：质量无法保证（自审不可靠） 🟠

**表现：**
- 同一个 Agent 既写代码又审代码，自我评估不可靠
- 把平庸输出叫做"完成"
- 跳过边缘情况和错误处理
- 遗漏集成问题

**Harness 解法：**

```
Generator-Evaluator 分离架构：

  Generator（写代码）              Evaluator（审代码）
  ┌─────────────────┐            ┌─────────────────┐
  │ 实现功能         │───────────▶│ 按合同评分        │
  │ 调用 Specialist  │   handoff  │ 检查边界情况      │
  │ 自检             │◀───────────│ 检查测试覆盖      │
  └─────────────────┘   反馈     │ 报告缺陷          │
                                   └─────────────────┘

Sprint Contract：
  ┌──────────────────────────────────────────────┐
  │ # Sprint Contract: [功能名称]                   │
  │                                                │
  │ ## Testable Behaviors                          │
  │ - [ ] B1.1: 正常流程走通  | Owner: backend-dev │
  │ - [ ] B1.2: 参数校验      | Owner: backend-dev │
  │ - [ ] B2.1: 页面渲染正确  | Owner: frontend-dev│
  │                                                │
  │ ## Acceptance Criteria                         │
  │ | ID | Criterion            | Pass | Fail |     │
  │ |====|======================|======|======|     │
  │ | A1 | 登录成功返回 token   |  ☐   |  ☐   |     │
  │ | A2 | 错误密码返回 401    |  ☐   |  ☐   |     │
  └──────────────────────────────────────────────┘

evaluation/ 评估模板：
  evaluation/criteria/bug-report.md        ← 缺陷报告模板
  evaluation/templates/evaluation-report.md ← 评估报告模板
```

**核心思路：** 永远不让同一个 Agent 既写又审。Generator 写完 → Evaluator 按合同逐条评分。

---

### 问题 5：Scope 蔓延 🟠

**表现：**
- 做一个用户登录功能，顺手改了导航栏样式
- 改一个 API 接口，顺便重构了另一个模块
- 功能越做越多，偏离了原始需求

**Harness 解法：**

```
Sprint Contract 的 Scope 条款：

  ## Scope
  - In Scope:   用户登录的 API + 前端页面
  - Out of Scope: 导航栏样式调整、用户注册功能

  如果 Agent 想改 Out of Scope 的内容 → 必须先提议新的 sprint contract
```

**核心思路：** 开工前明确什么做、什么不做，超出范围的改动必须新建 contract。

---

### 问题 6：无进度追踪 🟡

**表现：**
- 长时间任务（重构、大功能）做到一半被打断，下次不知道从哪继续
- 多 Agent 协作时不知道彼此完成了什么
- 无法判断项目整体进度

**Harness 解法：**

```
specs/active/01-user-auth-plan.md  ← 当前 sprint 的完整计划
  ├─ 阶段 1: 后端 API（完成 ✅）
  ├─ 阶段 2: 前端页面（进行中 ⏳）
  └─ 阶段 3: 联调测试（待开始 ⬜）

skills/checkpoint/  → 保存当前进度到文件
skills/resume/      → 从 checkpoint 恢复
```

**核心思路：** spec 就是进度单，完成一项勾一项。Checkpoint 保存上下文，Resume 恢复。

---

### 问题 7：多模块/多文件协作困难 🟡

**表现：**
- 改一个功能涉及后端 API + 前端页面 + 数据库 migration
- Agent 在不同文件间切换时丢失上下文
- 前后端接口定义不一致

**Harness 解法：**

```
Domain Specialist 分工：

  Generator（总协调）
    ├─ 委托 backend-dev    → 写 API 接口
    ├─ 委托 frontend-dev   → 写前端页面
    ├─ 委托 database-dev   → 写 migration
    └─ 自检：接口定义是否一致

  api-contract.md （接口契约）：
    POST /api/v1/login
    Request:  { username: string, password: string }
    Response: { token: string, expires_in: number }
```

**核心思路：** Generator 不自己干所有活，而是委托给 Specialist，然后做整合和接口对齐。

---

### 问题 8：私域组件/内部库不识 🟡

**表现：**
- 项目用了内部组件库（ProTable、ProForm 等），模型训练数据里没有
- Agent 写出的代码经常用错 prop 或漏掉必填配置
- 维护文档总是滞后于代码实现

**Harness 解法：**

```
AGENTS.md 中说明：
  ## 私域组件
  参考项目在 reference-projects/ 目录下
  组件源码在 component-lib/src/ 目录下
  写 UI 代码前先读参考项目中的使用示例

reference-projects/ （参考项目目录）
  ├── user-management/    ← 用户管理模块的完整实现
  └── order-management/   ← 订单模块的完整实现

# 关键：引用源码而非维护文档——源码不过时
```

**核心思路：** 源码就是最准确的文档。把参考项目放仓库里，Agent 不会写的时候直接读源码。

---

### 问题 9：环境配置不一致 🟡

**表现：**
- 有人用 IDE JVM 参数，有人用 shell export，有人写在 .bashrc 里
- 启动脚本在 A 的电脑上能跑，在 B 的电脑上报错
- Agent 不知道环境变量在哪

**Harness 解法：**

```
~/.<project>_env  ← 统一环境变量文件（放 ~/ 下避免提交到 Git）
  DB_URL=jdbc:mysql://localhost:3306/myapp
  REDIS_URL=redis://localhost:6379

scripts/start-server.sh
  # 自动 source 环境变量文件（不存在则跳过）
  [ -f ~/.myapp_env ] && source ~/.myapp_env

AGENTS.md 中写明：
  ## 环境配置
  1. 查看 ~/.myapp_env（不存在则用 application.yml 默认值）
  2. ./scripts/start-server.sh 启动
```

**核心思路：** 统一环境变量配置 + 一键启动脚本，Agent 和人都走同一套流程。

---

### 问题 10：记忆与连续性 🟠

**表现：**
- Agent 每次醒来不记得之前的用户偏好和项目经验
- 之前踩过的坑下次又踩一遍
- 调试过程中发现的有用信息，下次 session 就没了

**Harness 解法：**

```
docs/lessons/ （经验教训沉淀）
  ├── 01-数据库连接池配置.md
  ├── 02-缓存失效场景.md
  └── 03-部署常见问题.md

skills/resume/（恢复技能）
  └─ 读取 handoff artifact，重建上下文

# Hermes 的记忆功能也可以配合使用
```

**核心思路：** 不要依赖模型的固有记忆，把经验写成文档放在项目里。Agent 每次醒来先读 lessons。

---

## 总结：Harness 解决问题的模式

从上面的分析可以看出，Harness 解决问题的核心模式只有三种：

| 模式 | 说明 | 对应问题 |
|------|------|---------|
| **写下来** | 把人的知识变成文件放在项目里 | 1, 2, 8, 10 |
| **封装起来** | 把操作步骤变成脚本，让 Agent 能自己执行 | 3, 9 |
| **分离开** | 把写代码和审代码分开，避免自我评估盲区 | 4, 5, 7 |

所谓"构建 Harness"，本质上就是做这三件事。
