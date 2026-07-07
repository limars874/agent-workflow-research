#!/usr/bin/env bash
# 核心强制件:安全护栏(C4)之一 —— 提交前扫密钥,别让 agent 把凭据提交进仓库。
# 触发器无关:手动 `./flow secret` 扫全仓;pre-commit 适配层传入暂存文件列表则只扫增量。
# 白名单:仓库根 .flowignore-secrets,每行一条正则(命中即忽略,用于误报)。

here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=common.sh
. "$here/common.sh"

root="$(flow_repo_root)"

# 常见凭据模式(可自行增补)
patterns='(ghp_[A-Za-z0-9]{20,})|(github_pat_[A-Za-z0-9_]{20,})|(AKIA[0-9A-Z]{16})|(sk-[A-Za-z0-9]{20,})|(-----BEGIN [A-Z ]*PRIVATE KEY-----)|(xox[baprs]-[A-Za-z0-9-]+)'

# 目标文件:参数给了就扫参数(增量),否则扫全部被跟踪文件
if [ "$#" -gt 0 ]; then
  files=("$@")
else
  mapfile -t files < <(git -C "$root" ls-files)
fi

ignore="$root/.flowignore-secrets"
hit=0
for f in "${files[@]}"; do
  [ -f "$root/$f" ] || [ -f "$f" ] || continue
  path="$f"; [ -f "$root/$f" ] && path="$root/$f"
  while IFS= read -r line; do
    # 白名单过滤
    if [ -f "$ignore" ] && printf '%s' "$line" | grep -qEf "$ignore"; then continue; fi
    flow_err "疑似密钥: $f — ${line:0:80}"
    hit=1
  done < <(grep -noE "$patterns" "$path" 2>/dev/null || true)
done

if [ "$hit" -ne 0 ]; then
  flow_err "发现疑似密钥 —— 拦截。误报请加白名单 .flowignore-secrets"
  exit "$EXIT_BLOCK"
fi
flow_ok "未发现密钥"
exit "$EXIT_PASS"
