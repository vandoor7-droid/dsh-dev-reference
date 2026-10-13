# dsh-dev-reference

DSH（DeepSeek Harness）源码与开发者文档的查阅、拉取与开发规范参考 —— 一个 DSH 插件开发用的 agent skill。

## 它做什么

- **DSH 插件开发规范**：范围与身份、包结构与 `cordis.patch.yml` 行模式、只用已发布公开接缝与缺接缝处理、版本兼容声明流程、测试与验证规范，以及 loader patch 索引范围、Cordis provide/isolate 语义、事件跨 realm 等实践陷阱。
- **官方文档的正确用法**：必读顺序（capability-seams → cordis-primer/cordis-api → config-catalog → …）与 `references/doc-map.md` 全量地图，按任务查该读哪篇。
- **按版本拿源码和文档**：npm `@deepseek-ai/dsh` 版本 ↔ 仓库 tag `dsh-v<版本>`；单篇文档 raw URL 直取，或整棵参考检出。
- **一键拉取/更新**：`scripts/refresh-dsh-reference.ps1` 解析版本 → clone/fetch tags → checkout 到对应 tag。

## 安装

放进 DSH 用户级技能目录即可被发现：

```powershell
# Windows
Copy-Item -Recurse dsh-dev-reference "$env:USERPROFILE\.dsh\skills\"
# Linux / macOS
cp -r dsh-dev-reference ~/.dsh/skills/
```

## 使用

直接在对话里问 DSH 内部实现/插件开发/查官方文档/拉最新源码类的问题，skill 会自动触发；也可显式调用 `dsh-dev-reference`。手动拉取参考：

```powershell
# Windows（PowerShell 5.1 / pwsh 均可）
& "$env:USERPROFILE\.dsh\skills\dsh-dev-reference\scripts\refresh-dsh-reference.ps1"
& "$env:USERPROFILE\.dsh\skills\dsh-dev-reference\scripts\refresh-dsh-reference.ps1" -Version 0.2.0-rc.2
# Linux / macOS
pwsh ~/.dsh/skills/dsh-dev-reference/scripts/refresh-dsh-reference.ps1
```

## 上游

源码与文档：[deepseek-ai/deepseek-harness](https://github.com/deepseek-ai/deepseek-harness)（本 skill 只读引用，不改动上游）。
