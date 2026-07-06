#!/usr/bin/env bash
# 核心强制件:独立审查(S6)—— 跨模型二审。
# 把 range 内的 diff + spec.md 喂给另一个模型的 headless CLI,令其找缺漏/糊弄/范围偏离。
# 设计要点:
#   - 跨模型 + fresh context = 真"独立"(审查方只看 diff 和 spec,看不到实现过程的自我叙事)
#   - fail-open:二审 CLI 未配或超时 → 放行 + 落盘告警(别 fail-closed,否则 API 一抖没法 push)
#   - 定位是"抓缺漏的网",硬门是 verify;输出含 BLOCK 才拦
# 二审命令通过环境变量注入(host 无关):
#   FLOW_REVIEW_CMD 读 stdin(diff+spec),输出评审;含 "BLOCK" 则判定拦截。
#   例:export FLOW_REVIEW_CMD='codex exec "对照下述 spec 审查此 diff,发现缺漏/mock糊弄/范围偏离则输出 BLOCK 并说明"'

here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=common.sh
. "$here/common.sh"

eval "$(flow_parse_range "$@")"
root="$(flow_repo_root)"
sha="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
outdir="$root/.flow/reviews"; mkdir -p "$outdir"
out="$outdir/$sha.md"

diff="$(git diff "$FLOW_RANGE" 2>/dev/null || true)"
if [ -z "$diff" ]; then
  flow_warn "range=$FLOW_RANGE 无 diff,跳过二审"
  exit "$EXIT_PASS"
fi

if [ -z "${FLOW_REVIEW_CMD:-}" ]; then
  flow_warn "未配 FLOW_REVIEW_CMD,跳过跨模型二审(fail-open)。配置见本文件头注释"
  echo "# $sha 跨模型二审:SKIPPED(未配 FLOW_REVIEW_CMD)" >"$out"
  exit "$EXIT_PASS"
fi

spec=""; [ -f "$root/spec.md" ] && spec="$(cat "$root/spec.md")"
payload=$(printf '## SPEC\n%s\n\n## DIFF (%s)\n```diff\n%s\n```\n' "$spec" "$FLOW_RANGE" "$diff")

flow_log "跨模型二审中(sha=$sha)…"
verdict="$(printf '%s' "$payload" | timeout 180 bash -c "$FLOW_REVIEW_CMD" 2>&1)" || {
  flow_warn "二审 CLI 出错/超时,fail-open 放行(已落盘告警)"
  { echo "# $sha 跨模型二审:ERROR/TIMEOUT(fail-open 放行)"; echo; echo "$verdict"; } >"$out"
  exit "$EXIT_PASS"
}

{ echo "# $sha 跨模型二审"; echo; echo "$verdict"; } >"$out"

if printf '%s' "$verdict" | grep -q 'BLOCK'; then
  flow_err "二审判定 BLOCK —— 拦截(详见 $out)"
  exit "$EXIT_BLOCK"
fi
flow_ok "二审通过(详见 $out)"
exit "$EXIT_PASS"
