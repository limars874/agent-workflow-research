#!/usr/bin/env bash
# 核心强制件:验证证据(S5)+ 完成权门禁(C5)。
# 契约:见 flow/CONTRACT.md —— 读 spec.md,写 .flow/evidence/。
# 从 spec.md 抽取每条 `verify: <命令>`,逐条运行;全绿=0,有红=1,自身出错=2。
# 触发器无关:手动 `./flow verify` 或 git pre-push 都调它。

here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=common.sh
. "$here/common.sh"

eval "$(flow_parse_range "$@")"
root="$(flow_repo_root)"
spec="$root/spec.md"

if [ ! -f "$spec" ]; then
  flow_warn "无 spec.md,跳过验证(range=$FLOW_RANGE)。约定:验收标准写成 'verify: <命令>'"
  exit "$EXIT_PASS"
fi

# 抽取 verify 行(形如:  verify: pnpm test foo)
mapfile -t cmds < <(grep -oE '^[[:space:]]*verify:[[:space:]]*.+' "$spec" | sed -E 's/^[[:space:]]*verify:[[:space:]]*//')

if [ "${#cmds[@]}" -eq 0 ]; then
  flow_warn "spec.md 里没有 verify: 行,无可执行验收"
  exit "$EXIT_PASS"
fi

flow_log "共 ${#cmds[@]} 条验收命令,逐条执行"
fail=0
mkdir -p "$root/.flow/evidence"
i=0
for c in "${cmds[@]}"; do
  i=$((i+1))
  log="$root/.flow/evidence/ac-$i.log"
  flow_log "→ [$i] $c"
  if bash -c "$c" >"$log" 2>&1; then
    flow_ok "[$i] $c"
  else
    flow_err "[$i] $c(见 .flow/evidence/ac-$i.log)"
    fail=1
  fi
done

if [ "$fail" -ne 0 ]; then
  flow_err "验收未全绿 —— 完成权门禁:不算完成,拦截"
  exit "$EXIT_BLOCK"
fi
flow_ok "全部验收通过"
exit "$EXIT_PASS"
