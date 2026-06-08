# Harness 持续优化 — Cron 任务方案

> **关联文档：** `~/docs/harness-research/dev-mode-flow.md` 第七节
> **版本：** v1.0 · 2026-06-07

---

## 一、设计原则

- **Agent 产生数据，Cron 聚合提醒** — 人只在关键节点收到通知
- **脚本静默原则** — 没有触发条件时不发消息，避免噪音
- **先简后繁** — 首版 3 个 cron，跑顺后再加

---

## 二、数据基础：`~/.hermes/metrics/`

```
~/.hermes/metrics/
├── deviations/           # 偏离事件（Agent 编码时写入）
│   └── <项目名>/
│       └── <功能名>.json
├── retros/               # 回顾摘要（Agent PR review 后写入）
│   └── <项目名>/
│       └── <功能名>.md
├── summary.json          # 汇总指标（Agent 每功能交付后更新）
└── .milestone            # 上次里程碑报告的功能数（脚本维护）
```

**summary.json 结构：**

```json
{
  "project": "<项目名>",
  "updated_at": "2026-06-07T10:00:00",
  "features": [
    {
      "name": "用户管理",
      "delivered_at": "2026-06-05",
      "spec_rounds": 1,
      "design_fixes": 2,
      "slice_count": 5,
      "slice_durations_min": [12, 8, 15, 10, 6],
      "deviation_count": 1,
      "retro_done": true
    }
  ],
  "totals": {
    "features_delivered": 1,
    "total_deviations": 1,
    "avg_spec_rounds": 1.0,
    "avg_design_fixes": 2.0,
    "avg_slice_duration": 10.2
  }
}
```

---

## 三、3 个 Cron 任务

### Job 1：每周指标周报

| 属性 | 值 |
|------|-----|
| **调度** | `0 9 * * 1`（每周一早 9:00） |
| **类型** | LLM-driven（需要 Agent 推理生成周报） |
| **输入** | `summary.json` |
| **输出** | 飞书消息：偏离趋势 / 返修率 / 切片耗时 / 功能交付数 |
| **静默** | 如果 summary.json 中本周无新功能，Agent 输出「本周无新增功能」的简短说明 |

### Job 2：功能里程碑检查

| 属性 | 值 |
|------|-----|
| **调度** | `0 9 * * *`（每天早 9:00） |
| **类型** | script-only（`no_agent=True`） |
| **脚本** | `~/docs/harness-research/scripts/check_feature_milestone.py`（通过 `~/.hermes/scripts/` 软链供 cron 调用） |
| **逻辑** | 读取 `summary.json` 的 `totals.features_delivered`，对比 `.milestone` 文件 |
| | 如果 ≤ 上次里程碑数 → **静默**（不发消息） |
| | 如果跨过 5 的倍数 → 飞书通知：「已完成 N 个功能，建议做 TDD 审计 + 决策边界评估」 |
| **静默** | 未触发时不发消息 |

### Job 3：Retro 遗漏检查

| 属性 | 值 |
|------|-----|
| **调度** | `0 10 * * *`（每天上午 10:00） |
| **类型** | script-only（`no_agent=True`） |
| **脚本** | `~/docs/harness-research/scripts/check_retro_gaps.py`（通过 `~/.hermes/scripts/` 软链供 cron 调用） |
| **逻辑** | 遍历 `summary.json` 中已交付功能，检查对应 `retros/<项目名>/<功能名>.md` 是否存在 |
| | 无遗漏 → **静默**（不发消息） |
| | 有遗漏 → 飞书通知：「以下功能已交付但未做回顾：xxx, yyy」 |
| **静默** | 无遗漏时不发消息 |

---

## 四、数据流

```
┌─────────────┐     ┌──────────────────┐     ┌──────────────┐
│ Agent 编码   │────→│ ~/.hermes/        │────→│ Cron 任务     │
│             │     │   metrics/        │     │              │
│ • 偏离记录   │     │   summary.json    │     │ Job 1: 周报   │
│ • 切片时间   │     │   deviations/     │     │ Job 2: 里程碑 │
│ • 交付统计   │     │   retros/         │     │ Job 3: Retro  │
│ • Retro 生成 │     │   .milestone      │     │              │
└─────────────┘     └──────────────────┘     └──────┬───────┘
                                                    │
                                              ┌─────▼──────┐
                                              │ 飞书通知    │
                                              └────────────┘
```

---

## 五、后续扩展（v1 之后考虑）

- **Job 4：偏离热点分析** — 统计哪种偏离类型出现频率最高，提醒改进 Spec 模板
- **Job 5：切片粒度优化建议** — 当某类功能切片耗时方差过大时，建议调整切片策略
- **Job 6：流程版本更新提醒** — 当指标持续恶化时，提醒回顾流程是否需要调整
