#!/usr/bin/env bash
# 核心件:任务状态单一写者(C1)。契约见 flow/CONTRACT.md —— 读写 .flow/state。
# 完成权铁律:本脚本负责 pending/running/blocked 与 step,但**拒绝写任何 done**。
#   done 只能由 verify.sh 在退出码 0 时写(完成权剥夺)。
# 触发器无关:手动 `./flow state ...` 或别的脚本调它。用法:
#   state.sh init <task>          初始化
#   state.sh step <name>          设置当前步骤(拒绝 done)
#   state.sh slice <id> <status>  设置切片状态(拒绝 done)
#   state.sh show                 打印

here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=common.sh
. "$here/common.sh"

root="$(flow_repo_root)"
STATE="$root/.flow/state"

_stamp() { # 更新 updated_by
  _set_line "updated_by" "updated_by: ${1:-state.sh}"
}
_set_line() { # _set_line <匹配前缀> <整行内容>:存在则替换,否则追加
  local key="$1" line="$2"
  mkdir -p "$root/.flow"; touch "$STATE"
  if grep -q "^${key}" "$STATE" 2>/dev/null; then
    # 用 awk 精确替换首个匹配行(避免 sed 特殊字符问题)
    awk -v k="^${key}" -v repl="$line" '!d && $0 ~ k {print repl; d=1; next} {print}' "$STATE" > "$STATE.tmp" && mv "$STATE.tmp" "$STATE"
  else
    printf '%s\n' "$line" >> "$STATE"
  fi
}

cmd="${1:-show}"; shift || true
case "$cmd" in
  init)
    task="${1:-untitled}"
    mkdir -p "$root/.flow"
    { echo "task: $task"; echo "step: grill"; echo "updated_by: state.sh"; } > "$STATE"
    flow_ok "state 初始化: $task"
    ;;
  step)
    name="${1:?用法: state.sh step <name>}"
    if [ "$name" = done ]; then flow_err "step=done 只能由 verify.sh 门禁写,拒绝"; exit "$EXIT_ERROR"; fi
    _set_line "step:" "step: $name"; _stamp "state.sh"
    flow_ok "step → $name"
    ;;
  slice)
    id="${1:?用法: state.sh slice <id> <status>}"; status="${2:?缺 status}"
    if [ "$status" = done ]; then flow_err "slice $id=done 只能由 verify.sh 门禁写,拒绝"; exit "$EXIT_ERROR"; fi
    _set_line "slice ${id}:" "slice ${id}: $status"; _stamp "state.sh"
    flow_ok "slice $id → $status"
    ;;
  show)
    [ -f "$STATE" ] && cat "$STATE" || echo "(无 .flow/state,尚未 init)"
    ;;
  derive)
    # 当前位置**据 artifact 推导**(不靠命令驱动,漏跑也不会错;抄 web-dev-skills 无状态重建)
    if grep -q "^step: done" "$STATE" 2>/dev/null; then echo done
    elif [ ! -f "$root/.flow/approved" ]; then echo grill
    elif [ ! -f "$root/spec.md" ]; then echo spec
    elif [ ! -f "$root/.flow/tasks.md" ]; then echo slice
    else
      # 注:grep -c 无匹配时打印 0 但退出 1,用 || true 吞掉退出码(不能用 || echo 0,会拼成两行)
      total=$(grep -coE '\] +T[0-9]+' "$root/.flow/tasks.md" 2>/dev/null || true)
      done_n=$(grep -c '^slice .*: done' "$STATE" 2>/dev/null || true)
      if [ "$total" -gt 0 ] && [ "$done_n" -ge "$total" ]; then echo review  # 切片都 done,待任务级收口/审查
      else echo implement; fi
    fi
    ;;
  *)
    echo "用法: state.sh <init|step|slice|show|derive> ..." >&2; exit "$EXIT_ERROR" ;;
esac
