#!/usr/bin/env bash
# 接线器:light / standard / max 三档 = 同一批核心件装多少触发器。
# 用 core.hooksPath 让 hook 随仓库走(版本控制在 flow/adapters/githooks,host 无关、可 review)。
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
root="$(git rev-parse --show-toplevel)"
hooks_src="$here/../adapters/githooks"

profile="${1:-}"
case "$profile" in
  light)
    git -C "$root" config --unset core.hooksPath 2>/dev/null || true
    echo "[light] 已卸载 hook 接线,退回手动 ./flow 跑(L1)。"
    ;;
  standard)
    git -C "$root" config core.hooksPath "flow/adapters/githooks"
    chmod +x "$hooks_src/pre-push"
    echo "[standard] 已接 pre-push(verify+review)。"
    echo "  ⚠ 硬门在服务端:请手动到 GitHub 给 main 开分支保护 + 把测试挂 required check。"
    ;;
  max)
    git -C "$root" config core.hooksPath "flow/adapters/githooks"
    chmod +x "$hooks_src/pre-push" "$hooks_src/pre-commit"
    echo "[max] 已接 pre-commit(secret)+ pre-push(verify+review)。"
    echo "  ⚠ 建议再补:commit-msg 追溯、CI required checks、放跑挡位。"
    ;;
  *)
    echo "用法: ./profiles/install.sh <light|standard|max>" >&2
    exit 2
    ;;
esac
