#!/usr/bin/env python3
"""检查功能交付里程碑——每跨越 5 的倍数时提醒做 TDD 审计 + 决策边界评估。

Cron 用法（no_agent=True）：stdout 为空时静默，有输出时飞书通知。
"""
import json
import os
from pathlib import Path

METRICS_HOME = Path(os.path.expanduser("~/.hermes/metrics"))
SUMMARY = METRICS_HOME / "summary.json"
MILESTONE = METRICS_HOME / ".milestone"

MILESTONE_INTERVAL = 5  # 每 N 个功能提醒一次


def main():
    if not SUMMARY.exists():
        return  # 还没开始，静默

    try:
        data = json.loads(SUMMARY.read_text())
    except (json.JSONDecodeError, OSError):
        return

    current = data.get("totals", {}).get("features_delivered", 0)

    # 读取上次里程碑
    try:
        last_milestone = int(MILESTONE.read_text().strip())
    except (ValueError, OSError):
        last_milestone = 0

    # 计算上次里程碑所在边界（向下取整到 MILESTONE_INTERVAL 的倍数）
    last_boundary = (last_milestone // MILESTONE_INTERVAL) * MILESTONE_INTERVAL
    current_boundary = (current // MILESTONE_INTERVAL) * MILESTONE_INTERVAL

    if current_boundary > last_boundary and current > 0:
        # 跨过了新的里程碑边界
        avg_spec = data.get("totals", {}).get("avg_spec_rounds", 0)
        avg_fixes = data.get("totals", {}).get("avg_design_fixes", 0)
        avg_slice = data.get("totals", {}).get("avg_slice_duration", 0)
        deviations = data.get("totals", {}).get("total_deviations", 0)

        # 更新里程碑
        MILESTONE.write_text(str(current))

        msg = (
            f"📊 里程碑提醒：已完成 {current} 个功能\n\n"
            f"建议执行：\n"
            f"1. TDD 审计（抽查一个功能的 git 时间线）\n"
            f"2. 决策边界评估（偏离 {deviations} 次 / Spec 平均 {avg_spec:.1f} 轮 / "
            f"设计修正 {avg_fixes:.1f} 点）\n\n"
            f"指标概览：\n"
            f"- 切片平均耗时：{avg_slice:.0f} 分钟\n"
            f"- 偏离次数/功能：{deviations / current:.1f}\n\n"
            f"可在飞书会话中让 Agent 生成详细报表。"
        )
        print(msg)
    # else: 未触发 → 静默（stdout 为空，no_agent=True 时不会发消息）


if __name__ == "__main__":
    main()
