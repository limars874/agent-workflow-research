# 示例:给导出功能加 CSV 格式

> 这是 spec.md 的填写范例(供 spec skill 参照)。真实使用时放仓库根,命令换成你项目的真命令。

## Requirements
- R1: 用户能把报表导出为 CSV
- R2: CSV 里的金额保留两位小数
- R3: 空报表导出得到只含表头的 CSV,不报错

## Seams
- CLI 命令 `app export --format csv <report-id>` 的 stdout(公开边界,不测内部 formatter 类)

## Acceptance
- AC1 (R1) 导出已知报表,得到合法 CSV
  verify: app export --format csv fixtures/report-1 | head -1 | grep -q ','
- AC2 (R2) 金额列两位小数
  verify: app export --format csv fixtures/report-1 | grep -qE '[0-9]+\.[0-9]{2}'
- AC3 (R3) 空报表只出表头且退出码 0
  verify: test "$(app export --format csv fixtures/empty | wc -l)" = "1"

## Out of scope
- 不做 Excel/xlsx 导出(另开需求)
- 不改现有 JSON 导出行为
