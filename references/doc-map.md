# docs/ 目录地图（读哪篇）

`deepseek-harness` 仓库 `docs/` 下每篇文档三件套：`<topic>.md`（英）、`<topic>.zh.md`（中）、`<topic>.i18n.yaml`。**读 `.zh.md`**。按任务挑一篇精读，不要通读；下面按"什么时候读"分组。行内路径均相对参考检出的 `docs/` 目录。

## 先读这几篇（理解全局）

| 文档 | 什么时候读 |
|---|---|
| `architecture.zh.md` | 第一次接触代码库；搞清 apps/packages 分层、Host/Web/TUI 各面如何组装 |
| `glossary.zh.md` | 遇到陌生术语（session/fiber/realm/preset/patch…）先查这里 |
| `capability-seams.zh.md` | **写插件前必读**：官方明示的可插拔接缝清单——"我能替换/扩展什么"以它为准，不在清单上的先当缺接缝处理 |
| `cordis-primer.zh.md` | 用到 Cordis 容器（ctx/服务/事件/插件生命周期）时；这是所有插件的运行时底座 |
| `development.zh.md` | 要跑起来/参与构建时：开发环境、命令、目录约定 |
| `testing.zh.md` | 写测试前：官方测试框架与各 vitest 配置（web/e2e/snapshot/perf）的分工 |

## 按子系统查实现

| 文档 | 什么时候读 |
|---|---|
| `subsystems/`（目录） | 按子系统细分的深度文档——会话、插件加载、权限、压缩等具体问题从这里进 |
| `agent-lifecycle.zh.md` | agent 循环、步骤钩子（pre/post-step）、自动压缩触发点 |
| `tool-execution-pipeline.zh.md` | 工具调用从下发到执行的全链路；审查/拦截/沙箱在哪一层介入 |
| `tool-catalog.zh.md` | 官方工具清单与各自参数 |
| `api-gateway.zh.md` | Host 网关面：客户端连接、远程调用、路由 |
| `event-producer-consumer.zh.md` | 官方事件的生产者/消费者对照——订阅某事件前先查它的发出方与生命周期 |
| `rescope.zh.md` | 作用域/域改造（rescope）相关问题 |

## 配置与扩展点

| 文档 | 什么时候读 |
|---|---|
| `config-catalog.zh.md` | 官方配置项全集——写 `cordis.patch.yml` 或 CLI 配置前查字段 |
| `experimental-persistence-catalog.zh.md` / `persistence-catalog.zh.md` | 涉及持久化 schema、session 格式时 |
| `session-format-status.zh.md` | session 文件格式版本与兼容性 |
| `deepseek-llm-api-wire-extensions.zh.md` | DeepSeek LLM 线协议扩展（自定义字段/行为） |
| `cli-help.zh.md` | CLI 参数与子命令速查 |

## 深入与排错

| 文档 | 什么时候读 |
|---|---|
| `cordis-api/`（目录） | Cordis 公开 API 的逐项参考；确认某个 API 是否"已发布"看这里 |
| `cordis-tutorial/`（目录） | 按教程学 Cordis 写法（比 primer 更动手） |
| `defensive-patterns.zh.md` | 官方防御式写法；插件代码风格对齐它 |
| `graph-atlas.zh.md` / `module-graph.zh.md` | 模块依赖图——找"谁引入了谁/改这里影响谁" |
| `upgrade-guide/`（目录） | 版本升级指南；**逐版本核对公开 API 变化**时按 release 查 |
| `postmortem/`（目录） | 官方事故复盘——踩到相似症状先翻这里 |
| `web-styling.zh.md` / `ui-radius.zh.md` | Web 端样式/圆角等 UI 规范 |
| `user/`（目录） | 面向最终用户的文档（不是开发者文档） |
| `cookbook/`（目录） | 官方示例与常用配方 |

## 仓库根目录的规范文件

- `CONTRIBUTING.zh.md` —— 贡献规范（格式化/lint/PR 约定）
- `AGENTS.md` / `CLAUDE.md` —— 给 AI agent 的仓库级指令（结构与 architecture 呼应）
- `BRAND_GUIDELINES.zh.md` —— 品牌与文案规范
- `SAFETY.zh.md` —— 安全边界

## 版本提示

文档随 tag 变化；raw URL 与本地检出都要钉住 `dsh-v<版本>`。升级兼容声明前，用 `git log --oneline <旧tag>..<新tag> -- docs` 看文档层面改了什么，再 diff `packages/` 对应实现。
