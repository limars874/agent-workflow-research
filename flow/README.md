# flow(占位名 · 强制件骨架 v0)

> 改名:只需 `git mv flow <新名>`,内部脚本不硬编码品牌名(全用相对路径)。
> 设计依据:`../05-个人装配方案.md`。

## 核心契约

强制件 = **触发器无关的独立可执行**;触发器只是薄适配层。

- 输入靠参数:`lib/verify.sh --range origin/main...HEAD`,核心自己算默认 range,不读 hook 特有的 stdin。
- 退出码即结论:`0=过 / 1=拦 / 2=错`。
- 单一职责:verify / review / secret-scan 各写各的。
- **L 级是接线决定**:手动跑 = L1,接到 git hook = L3。代码不改,接线=升级。

## 目录

```
flow
├── flow                      手动入口:./flow <verify|review|secret|check|status>
├── lib/                      核心强制件(触发器无关)
│   ├── common.sh             共享:退出码、range 计算、日志
│   ├── verify.sh             跑 spec 里的 verify 命令(完成权门禁)
│   ├── review.sh             跨模型审 diff(fail-open + 落盘)
│   └── secret-scan.sh        扫密钥
├── adapters/githooks/        薄适配层(每个三五行,调 lib/)
│   ├── pre-push              verify + review
│   └── pre-commit            secret-scan
└── profiles/install.sh       接线器:light / standard / max 三档
```

## 用法

```bash
# 手动跑(L1,零接线)
./flow secret                       # 扫密钥
./flow verify                       # 跑 spec.md 里的验收命令
./flow check                        # secret + verify + review 全跑
./flow verify --range main...HEAD   # 指定范围

# 接线成 L3(想强制时)
./profiles/install.sh standard      # 装 pre-push + 提示配分支保护
./profiles/install.sh light         # 卸掉所有 hook,退回手动
```

## 约定文件(仓库根)

- `spec.md` — 验收标准,每条含 `verify: <可跑命令>`;verify.sh 抽取并逐条跑。
- `.flow/` — 运行态:`state.json`(任务状态)、`evidence/`(证据)、`reviews/<sha>.md`(审查结论)。
- `.flowignore-secrets`(可选)— secret-scan 的白名单正则,每行一条。

## 现状(v0)

- ✅ 契约、入口、退出码、range 计算、适配层、三档接线器可跑
- ✅ secret-scan 基础可用;verify 能抽取并执行 `spec.md` 的 verify 行
- ⏳ review 是 fail-open 骨架(靠 `FLOW_REVIEW_CMD` 指定二审模型 CLI,未配则告警放行)
- ⏳ state.json/recover、断言防护、commit-msg 追溯待补
