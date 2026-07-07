#!/usr/bin/env bash
# flow 门禁的回归测试(抄 consensus-rnd:门禁脚本自己要有测试,改坏了 CI 会红)。
# 跨模型审用 mock(FLOW_REVIEW_CMD)——测管路通不通,不测判断质量。
# 用法:./flow/test/smoke.sh   全过退出 0,任一失败退出 1。
set -u
FLOWDIR=$(cd "$(dirname "$0")/.." && pwd)
PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); printf '  \033[32m✓\033[0m %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  \033[31m✗\033[0m %s\n' "$1"; }
# assert_exit <期望码> <说明> <命令...>
assert_exit() { local want="$1" msg="$2"; shift 2; "$@" >/dev/null 2>&1; local got=$?; [ "$got" = "$want" ] && ok "$msg (exit $got)" || bad "$msg (期望 $want 得 $got)"; }
mkrepo() { local d; d=$(mktemp -d); ( cd "$d"; git init -q; printf '.flow/\n' > .gitignore; echo x > README.md; git add -A; git commit -q -m init ); echo "$d"; }

echo "== secret-scan =="
# 假 token 动态拼接,使本文件源码里**不含**可被扫中的字面量(否则扫 flow 仓库会误报自己)
faketok="ghp_$(printf 'A%.0s' $(seq 1 36))"
d=$(mkrepo); cd "$d"   # 必须在临时仓库内跑(否则会去扫当前仓库)
assert_exit 0 "干净仓库放行" "$FLOWDIR/lib/secret-scan.sh"
printf 'k="%s"\n' "$faketok" > leak.js
assert_exit 1 "命中假 token 拦截" "$FLOWDIR/lib/secret-scan.sh" leak.js
cd "$FLOWDIR"; rm -rf "$d"

echo "== verify(任务级)=="
d=$(mkrepo); cd "$d"
printf '# t\n## Acceptance\n- AC1\n  verify: test -f README.md\n' > spec.md
assert_exit 0 "全绿放行" "$FLOWDIR/lib/verify.sh"
printf '# t\n## Acceptance\n- AC1\n  verify: test -f NOPE\n' > spec.md
assert_exit 1 "有红拦截" "$FLOWDIR/lib/verify.sh"
cd "$FLOWDIR"; rm -rf "$d"

echo "== 完成权(state.sh 拒写 done)=="
d=$(mkrepo); cd "$d"; "$FLOWDIR/lib/state.sh" init t >/dev/null
assert_exit 2 "state.sh 拒写 slice done" "$FLOWDIR/lib/state.sh" slice T1 done
assert_exit 2 "state.sh 拒写 step done" "$FLOWDIR/lib/state.sh" step done
assert_exit 0 "state.sh 允许 running" "$FLOWDIR/lib/state.sh" slice T1 running
cd "$FLOWDIR"; rm -rf "$d"

echo "== 完成权(verify 是 done 唯一写者)=="
d=$(mkrepo); cd "$d"; "$FLOWDIR/lib/state.sh" init t >/dev/null
printf '# t\n## Acceptance\n- AC1\n  verify: test -f NOPE\n' > spec.md
"$FLOWDIR/lib/verify.sh" --complete >/dev/null 2>&1
if grep -q done .flow/state 2>/dev/null; then bad "验收失败却出现 done"; else ok "验收失败后 state 无 done"; fi
printf '# t\n## Acceptance\n- AC1\n  verify: test -f README.md\n' > spec.md
"$FLOWDIR/lib/verify.sh" --complete >/dev/null 2>&1
grep -q "^step: done" .flow/state && ok "全绿后 verify 写 step done" || bad "全绿却没写 done"
cd "$FLOWDIR"; rm -rf "$d"

echo "== 切片级 verify + T1/T10 边界 =="
d=$(mkrepo); cd "$d"; "$FLOWDIR/lib/state.sh" init t >/dev/null; mkdir -p .flow
cat > .flow/tasks.md <<'EOF'
- [ ] T1 一
  verify: test -f README.md
- [ ] T10 十(命令不同,验边界)
  verify: test -f NOPE_T10
EOF
"$FLOWDIR/lib/verify.sh" --complete-slice T1 >/dev/null 2>&1
grep -q "^slice T1: done" .flow/state && ok "complete T1 跑本片 verify 且未误命中 T10" || bad "T1 完成异常(可能误命中 T10)"
cd "$FLOWDIR"; rm -rf "$d"

echo "== 跨模型审(mock 管路)=="
d=$(mkrepo); cd "$d"
printf '# t\n## Acceptance\n- AC1\n  verify: true\n' > spec.md; git add -A; git commit -q -m s
echo "feature" > f.txt; git add -A; git commit -q -m f
cap=$(mktemp)
FLOW_REVIEW_CMD="cat > $cap; echo 没问题" "$FLOWDIR/lib/review.sh" --range HEAD~1...HEAD >/dev/null 2>&1
r=$?; { [ "$r" = 0 ] && grep -q "## DIFF" "$cap" && grep -q feature "$cap"; } && ok "mock 放行:管路把 spec+diff 喂对且放行" || bad "mock 放行管路异常"
FLOW_REVIEW_CMD='cat >/dev/null; echo "BLOCK: x"' "$FLOWDIR/lib/review.sh" --range HEAD~1...HEAD >/dev/null 2>&1
[ $? = 1 ] && ok "mock 判 BLOCK 时拦截" || bad "BLOCK 未拦截"
rm -f "$cap"; cd "$FLOWDIR"; rm -rf "$d"

echo "== 接线件 approve/summary/learn =="
d=$(mkrepo); cd "$d"
assert_exit 0 "approve 写文件" "$FLOWDIR/lib/record.sh" approve "决议"
[ -f .flow/approved ] && ok ".flow/approved 存在" || bad ".flow/approved 缺失"
"$FLOWDIR/lib/record.sh" summary "s" >/dev/null 2>&1; [ -f .flow/summary.md ] && ok ".flow/summary.md 存在" || bad "summary 缺失"
"$FLOWDIR/lib/record.sh" learn "l" >/dev/null 2>&1; [ -f .flow/learnings.md ] && ok ".flow/learnings.md 存在" || bad "learnings 缺失"
cd "$FLOWDIR"; rm -rf "$d"

echo
echo "== 结果:通过 $PASS,失败 $FAIL =="
[ "$FAIL" = 0 ] && { echo "全绿。"; exit 0; } || { echo "有红。"; exit 1; }
