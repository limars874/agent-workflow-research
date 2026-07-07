#!/usr/bin/env bash
# 核心强制件:验证证据(S5)+ 完成权门禁(C5)。
# 契约:见 flow/CONTRACT.md —— 读 spec.md,写 .flow/evidence/;**本脚本是 done 的唯一写者**。
# 从 spec.md 抽取每条 `verify: <命令>`,逐条运行;全绿=0,有红=1,自身出错=2。
# 完成权(可选):
#   --complete           全绿时写 `step: done`(任务级完成)
#   --complete-slice <id> 全绿时写 `slice <id>: done`(切片级完成)
#   未全绿则一律不碰 state(LLM 无法自证完成)。
# 触发器无关:手动 `./flow verify` 或 git pre-push 都调它。

here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=common.sh
. "$here/common.sh"

# 解析完成权标志(在 flow_parse_range 之前,后者会忽略未知参数)
complete_task=0; complete_slice=""
_args=("$@")
for ((j=0; j<${#_args[@]}; j++)); do
  case "${_args[$j]}" in
    --complete) complete_task=1 ;;
    --complete-slice) complete_slice="${_args[$((j+1))]:-}" ;;
  esac
done

eval "$(flow_parse_range "$@")"
root="$(flow_repo_root)"
spec="$root/spec.md"
STATE="$root/.flow/state"

# done 的唯一写入点(仅本脚本、仅全绿后调用)
_write_done() {
  local key="$1" line="$2"
  mkdir -p "$root/.flow"; touch "$STATE"
  if grep -q "^${key}" "$STATE" 2>/dev/null; then
    awk -v k="^${key}" -v repl="$line" '!d && $0 ~ k {print repl; d=1; next} {print}' "$STATE" > "$STATE.tmp" && mv "$STATE.tmp" "$STATE"
  else printf '%s\n' "$line" >> "$STATE"; fi
  _write_done_stamp
}
_write_done_stamp() {
  if grep -q "^updated_by" "$STATE" 2>/dev/null; then
    awk '!d && /^updated_by/ {print "updated_by: verify.sh"; d=1; next} {print}' "$STATE" > "$STATE.tmp" && mv "$STATE.tmp" "$STATE"
  else printf 'updated_by: verify.sh\n' >> "$STATE"; fi
}

# 验收命令来源:
#   --complete-slice <id> → 跑 .flow/tasks.md 里该切片自己的 verify(切片级)
#   否则                  → 跑 spec.md 全部 AC 的 verify(任务级)
tasks="$root/.flow/tasks.md"
if [ -n "$complete_slice" ]; then
  if [ ! -f "$tasks" ]; then
    flow_err "要按切片验收但无 .flow/tasks.md(先跑 slice)"; exit "$EXIT_ERROR"
  fi
  # 抽取该切片块(从 '] <id>' 到下一个 '- [' 之间)的 verify 行,id 精确匹配(T1 不误命中 T10)
  mapfile -t cmds < <(awk -v id="$complete_slice" '
    $0 ~ ("\\] +" id "([^0-9]|$)") {inblk=1; next}
    inblk && /^- \[/ {inblk=0}
    inblk && /^[[:space:]]*verify:/ {sub(/^[[:space:]]*verify:[[:space:]]*/,""); print}
  ' "$tasks")
  src="切片 $complete_slice"
else
  if [ ! -f "$spec" ]; then
    flow_warn "无 spec.md,跳过验证(range=$FLOW_RANGE)。约定:验收标准写成 'verify: <命令>'"
    exit "$EXIT_PASS"
  fi
  mapfile -t cmds < <(grep -oE '^[[:space:]]*verify:[[:space:]]*.+' "$spec" | sed -E 's/^[[:space:]]*verify:[[:space:]]*//')
  src="spec.md"
fi

if [ "${#cmds[@]}" -eq 0 ]; then
  flow_warn "$src 里没有可执行的 verify: 行"
  exit "$EXIT_PASS"
fi

flow_log "[$src] 共 ${#cmds[@]} 条验收命令,逐条执行"
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
  flow_err "验收未全绿 —— 完成权门禁:不算完成,拦截(state 未动)"
  exit "$EXIT_BLOCK"
fi
flow_ok "全部验收通过"

# 全绿后,且仅在此,才允许写 done(完成权剥夺:LLM 走不到这个分支)
if [ -n "$complete_slice" ]; then
  _write_done "slice ${complete_slice}:" "slice ${complete_slice}: done"
  flow_ok "完成权已授予 slice ${complete_slice}: done(由 verify.sh 写)"
elif [ "$complete_task" -eq 1 ]; then
  _write_done "step:" "step: done"
  flow_ok "完成权已授予 step: done(由 verify.sh 写)"
fi
exit "$EXIT_PASS"
