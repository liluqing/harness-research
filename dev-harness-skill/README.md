# dev-harness-skill

> Harness 开发流程的可执行实现。Agent 加载此 Skill 后，按 4 阶段执行从需求到交付的完整流程。

## 目录结构

```
dev-harness-skill/
├── README.md
├── skill.md                              # 总入口 Skill（编排 4 阶段）
│
├── phase-1-product-prototype/            # 产品与原型阶段
│   ├── flow.md                           #   流程定义
│   └── templates/
│       ├── prd.md                        #   PRD 模板
│       └── prototype-brief.md            #   原型简报模板
│
├── phase-2-architecture/                 # 架构设计和技术分析（可选）
│   ├── README.md                         #   🚧 待设计
│   └── templates/                        #   待补充
│
├── phase-3-spec-dev/                     # Spec 和开发阶段
│   ├── flow.md                           #   流程定义
│   ├── rules/
│   │   └── decision-boundary.md          #   Spec 决策树判断标准
│   └── templates/
│       ├── spec.md                       #   Spec 模板
│       ├── design.md                     #   技术设计模板
│       ├── ui.md                         #   前端设计模板
│       ├── test-case.md                  #   测试用例模板
│       └── slice-task.md                 #   切片任务卡片模板
│
├── phase-4-integration-test/             # 集成测试阶段
│   ├── README.md                         #   🚧 待设计
│   └── templates/                        #   待补充
│
├── shared/                               # 跨阶段共享
│   ├── project-context.md                #   项目上下文模板
│   └── state.json                        #   状态文件模板
│
└── scripts/ -> ../scripts/               # Cron 检测脚本
```

## 四阶段

| 阶段 | 输入 | 产出 | 状态 |
|------|------|------|:--:|
| Phase 1: 产品与原型 | 用户原始需求 | PRD + 原型 HTML | ✅ |
| Phase 2: 架构设计 | PRD | 架构文档 + 任务拆解 | 🚧 |
| Phase 3: Spec & 开发 | 任务 + PRD + 项目上下文 | 源代码 + 测试 | ✅ |
| Phase 4: 集成测试 | 已完成任务 | 集成测试报告 | 🚧 |
