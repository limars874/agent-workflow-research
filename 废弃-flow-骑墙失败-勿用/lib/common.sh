#!/usr/bin/env bash
# 共享库:退出码约定、range 计算、日志。所有 lib/ 脚本 source 它。
# 契约:0=过 / 1=拦 / 2=错(触发器无关的通用语言)。

set -euo pipefail

readonly EXIT_PASS=0
readonly EXIT_BLOCK=1
readonly EXIT_ERROR=2

# 仓库根(不依赖调用位置)
flow_repo_root() { git rev-parse --show-toplevel 2>/dev/null || pwd; }

# 从 --range 参数取范围;缺省用 origin/main...HEAD,首次推送(无 origin/main)则退化为全部提交。
# 用法:eval "$(flow_parse_range "$@")" 之后用 $FLOW_RANGE
flow_default_range() {
  # 无任何提交(空仓库):无 range 可算,回空(review 会据此跳过)
  if ! git rev-parse --verify -q HEAD >/dev/null 2>&1; then
    echo ""; return
  fi
  if git rev-parse --verify -q origin/main >/dev/null 2>&1; then
    echo "origin/main...HEAD"
  elif git rev-parse --verify -q main >/dev/null 2>&1; then
    echo "main...HEAD"
  else
    # 无基线:全部历史
    echo "$(git rev-list --max-parents=0 HEAD 2>/dev/null | tail -1)...HEAD"
  fi
}

# 解析 --range,回显 export 语句
flow_parse_range() {
  local range=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --range) range="$2"; shift 2;;
      --range=*) range="${1#--range=}"; shift;;
      *) shift;;
    esac
  done
  [ -n "$range" ] || range="$(flow_default_range)"
  printf 'export FLOW_RANGE=%q\n' "$range"
}

# 日志:统一前缀,写 stderr(stdout 留给结构化输出)
flow_log()  { printf '\033[36m[flow]\033[0m %s\n' "$*" >&2; }
flow_ok()   { printf '\033[32m[flow] ✓\033[0m %s\n' "$*" >&2; }
flow_warn() { printf '\033[33m[flow] ⚠\033[0m %s\n' "$*" >&2; }
flow_err()  { printf '\033[31m[flow] ✗\033[0m %s\n' "$*" >&2; }
