<!-- 项目约束库(mattpocock 缺的那块)。放 docs/agents/constraints.md。
     放"从代码不一定看得出、但每个任务都得遵守"的约束:技术选型、架构规矩、风格规范。
     别放术语(那是 CONTEXT.md)、别放一次性决策理由(那是 docs/adr/)。
     项目大了就把前端/后端各自拆到 docs/agents/frontend.md、backend.md,这里只留通用 + 指过去。
     每条约束尽量带"为什么"或一处代码路径为证,便于 AI 理解与遵守。 -->

# 项目约束

## 技术选型(锁定的栈/库,不得擅自替换)
- [例:HTTP 请求统一走 `src/lib/http.ts` 的封装,不直接用 fetch/axios —— 为了统一重试与鉴权]

## 架构约束
- [例:分层依赖方向 UI → service → repository,禁止反向;跨模块只经 `src/<mod>/index.ts` 公开面]

## 风格规范(从代码推断不出的那些)
- [例:金额一律用 `Money` 类型,禁止裸 number;时间一律 UTC ISO]

## 大块约束(项目大时拆出去)
- 前端整套:见 `docs/agents/frontend.md`
- 后端整套:见 `docs/agents/backend.md`
