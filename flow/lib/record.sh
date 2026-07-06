#!/usr/bin/env bash
# 契约写入便利件:把 prose-skill 的产出接到契约 artifact 上(不改 skill 本身)。
# 契约见 flow/CONTRACT.md。
#   record.sh approve [决议]   写 .flow/approved(grill 对齐后调)
#   record.sh summary <文本>   追加 .flow/summary.md(implement 每片记账)
#   record.sh learn  <文本>    追加 .flow/learnings.md(retro 回写调)
# 触发器无关:手动 `./flow approve` / `./flow summary` / `./flow learn` 或别的件调它。
# 说明:本脚本是**契约 append 日志的单一入口**(approved/summary/learnings 都经此写,格式统一)。

here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=common.sh
. "$here/common.sh"

root="$(flow_repo_root)"; mkdir -p "$root/.flow"
cmd="${1:-}"; shift || true
case "$cmd" in
  approve)
    dec="${*:-（未填决议）}"
    printf '%s approved: %s\n' "$(date -u +%FT%TZ)" "$dec" >> "$root/.flow/approved"
    flow_ok "已写 .flow/approved(implement 开工前置)"
    ;;
  summary)
    [ "$#" -gt 0 ] || { flow_err "用法: summary <文本>"; exit "$EXIT_ERROR"; }
    printf '%s %s\n' "$(date -u +%FT%TZ)" "$*" >> "$root/.flow/summary.md"
    flow_ok "已追加 .flow/summary.md(供 review/retro 读)"
    ;;
  learn)
    [ "$#" -gt 0 ] || { flow_err "用法: learn <文本>"; exit "$EXIT_ERROR"; }
    printf '\n## %s\n- %s\n' "$(date -u +%FT%TZ)" "$*" >> "$root/.flow/learnings.md"
    flow_ok "已追加 .flow/learnings.md(稳定项记得毕业进 AGENTS.md)"
    ;;
  *)
    echo "用法: record.sh <approve|summary|learn> ..." >&2; exit "$EXIT_ERROR" ;;
esac
