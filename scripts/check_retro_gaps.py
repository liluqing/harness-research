#!/usr/bin/env python3
"""检查是否有已交付但未做 Retro 的功能。

Cron 用法（no_agent=True）：stdout 为空时静默，有遗漏时飞书通知。
"""
import json
import os
from pathlib import Path

METRICS_HOME = Path(os.path.expanduser("~/.hermes/metrics"))
SUMMARY = METRICS_HOME / "summary.json"
RETROS_DIR = METRICS_HOME / "retros"


def main():
    if not SUMMARY.exists():
        return  # 还没开始，静默

    try:
        data = json.loads(SUMMARY.read_text())
    except (json.JSONDecodeError, OSError):
        return

    features = data.get("features", [])
    project = data.get("project", "default")
    missing = []

    for f in features:
        if f.get("retro_done", False):
            continue
        retro_file = RETROS_DIR / project / f"{f['name']}.md"
        if not retro_file.exists():
            missing.append(f["name"])

    if missing:
        names = "、".join(missing)
        msg = (
            f"📝 Retro 遗漏提醒\n\n"
            f"以下 {len(missing)} 个功能已交付但尚未做回顾：\n"
            f"{names}\n\n"
            f"可在飞书会话中让 Agent 补做回顾。"
        )
        print(msg)
    # else: 无遗漏 → 静默


if __name__ == "__main__":
    main()
