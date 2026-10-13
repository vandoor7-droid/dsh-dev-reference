---
name: dsh-dev-reference
description: DSH（DeepSeek Harness）插件开发规范与官方文档/源码的查阅、拉取参考。只要任务涉及 DeepSeek Harness / dsh 插件——写插件、cordis.patch.yml 配置、Cordis 服务注册、Agent 预设、会话与压缩、权限与自动审查、包结构与 bundle 声明、版本兼容声明、核对官方行为、排查与官方不一致的问题——就使用本 skill，即使用户没说"查文档"或"源码"。Use this skill whenever a task touches dsh plugin development standards, requires DeepSeek Harness developer docs (docs/*.md), needs to pull the dsh source tree or its tags (dsh-v*), verify a released public API before calling it, or decide how to react when a required public seam is missing.
---

# DSH 插件开发规范与官方文档参考

本 skill 覆盖三部分：当前版本的官方文档与源码获取（§1）、拉取最新源码与开发者文档（§2）、DSH 插件开发规范与要求（§3）。任何"官方是怎么实现的/这个接口能不能这样用/这个插件这样写对不对"的判断，先取到对应版本的官方文档与源码再下结论，结论里注明版本与文件路径。

DSH Core（`@deepseek-ai/dsh` 与官方 `@deepseek-ai/dsh-*` 包）及其源码检出一律**只读**；一切实现、适配、测试留在插件仓库。

## 1. 当前版本的官方文档与源码（在线获取）

### 版本与 tag

- npm `@deepseek-ai/dsh` 版本 `X.Y.Z-*` ↔ 仓库 tag `dsh-vX.Y.Z-*`（如 `0.2.0-rc.2` ↔ `dsh-v0.2.0-rc.2`）。查最新：`npm view @deepseek-ai/dsh version`；**核对行为以目标部署实际运行的版本为准**。
- 官方仓库（公开）：`https://github.com/deepseek-ai/deepseek-harness`（默认分支 `master`）。

### 文档地图（写插件前按此读，详见 `references/doc-map.md`）

`docs/` 下每篇三件套：`<topic>.md` / `<topic>.zh.md`（中文）/ `<topic>.i18n.yaml`——**读 `.zh.md`**。插件开发的必读顺序：

1. **`docs/capability-seams.zh.md`** —— 官方明示的可插拔接缝清单。插件能替换/扩展什么以它为准；不在清单上的能力先按"缺接缝"处理（§3.3）。
2. **`docs/cordis-primer.zh.md` + `docs/cordis-api/`** —— 插件运行时底座（ctx/服务/事件/生命周期）与公开 API 逐项参考；确认 API 是否"已发布"看这里。
3. **`docs/config-catalog.zh.md`** —— 官方配置项全集，写 `cordis.patch.yml` / CLI 配置前查字段。
4. **`docs/architecture.zh.md` + `docs/glossary.zh.md`** —— apps/packages 分层与术语，第一次接触先读。
5. **`docs/development.zh.md` / `docs/testing.zh.md`** —— 官方构建与测试约定（各 vitest 配置分工）。
6. **`docs/upgrade-guide/`** —— 声明版本兼容前，按 release 查公开 API 变化。
7. 需要具体子系统（会话、工具管线、权限、持久化…）时进 `docs/subsystems/`；全量地图见 `references/doc-map.md`。

### 三个获取入口

1. **单文档直取（不 clone）**——raw URL 模板：

   ```
   https://raw.githubusercontent.com/deepseek-ai/deepseek-harness/dsh-v<版本>/docs/<文件名>.md
   ```

2. **完整参考检出**——`scripts/refresh-dsh-reference.ps1`（见 §2），之后全部检索在本地做。

3. **已安装实现（最终依据）**——npm 全局/运行时安装目录里的 `@deepseek-ai/dsh*/lib/*.js` 是线上真实行为；**文档与实现冲突时以实现为准**，并把差异记下来。

## 2. 拉取最新源码与开发者文档

### 一键脚本（Windows PowerShell 5.1 / pwsh 均可）

```powershell
& "$env:USERPROFILE\.dsh\skills\dsh-dev-reference\scripts\refresh-dsh-reference.ps1"                # npm 最新版本
& "$env:USERPROFILE\.dsh\skills\dsh-dev-reference\scripts\refresh-dsh-reference.ps1" -Version 0.2.0-rc.2   # 指定版本
& "$env:USERPROFILE\.dsh\skills\dsh-dev-reference\scripts\refresh-dsh-reference.ps1" -Destination reference/deepseek-harness
# Linux/macOS：pwsh ~/.dsh/skills/dsh-dev-reference/scripts/refresh-dsh-reference.ps1
```

脚本：解析版本（参数 → npm）→ tag `dsh-v<版本>` → clone（blobless）或 `fetch --tags` → checkout 到该 tag → 打印路径。默认检出到用户级缓存 `~/.dsh/reference/deepseek-harness`（所有仓库之外）；在插件仓库内工作时用 `-Destination` 指到该仓库 **git-ignored** 的 `reference/`。检出只读：不改、不跟 `master`（master 是未发布行为，不代表任何部署）。

### 手动等价命令

```powershell
git clone --filter=blob:none https://github.com/deepseek-ai/deepseek-harness.git <目标目录>
git -C <目标目录> fetch --tags --force origin
git -C <目标目录> checkout --detach dsh-v<版本>
```

换版本 = `fetch --tags` + checkout 新 tag；看两版差异：`git log --oneline <旧tag>..<新tag> -- docs packages`。

### 网络回退

1. 全局搜索回退规则：原生 `web_search` ↔ 插件 `web_search_pro`（同一查询词互相重试）；
2. 仍不可用 → 核对已安装官方包实现，结论标注"依据已安装实现 x.y.z"；
3. 任何情况下不臆断官方行为。

## 3. DSH 插件开发规范与要求

### 3.1 范围与身份

- 插件的功能范围以项目冻结范围文档（如 `PRODUCT.md`）为唯一权威；不在范围内的能力不做，用既有官方机制兜底。
- 实现、兼容适配、测试、构建规则**全部在插件仓库内**；DSH Core 与官方检出只读。
- 保持产品/包/品牌标识（bundle、package name、页面身份）不被改动。
- 项目级政策（范围、发布、措辞）以目标仓库 `AGENTS.md` / `PRODUCT.md` 为准；本 skill 给的是通用规范。

### 3.2 包结构与注册规范

- 插件是标准 npm 包：入口经 `exports` 暴露，公开类型随 `lib/types/**/*.d.ts` 一起发布（仅 `.js` 不够，消费者按 types 解析）。
- 包元数据 `package.json` 的 `dsh` 字段声明插件怎么接入宿主：`bundle.patch`（随包加载的 `cordis.patch.yml`）、`client`（inject 面）、`platform`、`compatibility.dshReleases`（已验证兼容的 DSH release 清单）。
- `cordis.patch.yml` 的行模式：**替换官方行 = 原行 `disabled: true`（保留原 name）+ insert 自己的行（唯一 id）**；id 定位的 `config` 是整体替换（不合并）；不存在的目标会 warn+skip——可选能力缺行是正常路径，要能容忍。
- 一个能力 = 一个模块 + 一个宿主行；共享能力（选型、读写设置）放同一个命名空间由一个行承载，后续能力只叠行、不再造第二个宿主。已保存的用户配置（settings id、card id、field id）跨重构保持幂等，不得把存量用户打回默认。
- 运行时只经公开面交互：`ctx.get` 公开服务、`ctx.on` 公开事件、公开 exports；命名遵循既有约定（服务名/事件名/命名空间）。

### 3.3 只用已发布公开接缝；缺接缝的处理

- 以 `docs/capability-seams.zh.md` + `docs/cordis-api/` + 包 exports 判断"是否公开"；私有字段、内部符号、未列入接缝清单的能力都不算公开。
- 需要的公开接缝**不存在**时：该运行时能力保持**禁用并显式报错**（不静默降级），把接缝记入上游提案（项目里的 `docs/seam-gap.md` 一类），待上游提供后启用。
- 不要用 hack 绕过接缝去达成范围外能力；范围外能力的正确答案是"不做，给用户替代路径"。

### 3.4 版本兼容声明规范（声明"兼容 x.y.z"前必须做完）

1. **逐版本核对**：该 release 的公开 API 变化 vs 插件实际调用点（用参考检出 diff + `docs/upgrade-guide/`）；
2. `pnpm run build` + 全部测试通过；
3. 在真实运行面验证（惯例：lab 平面 `DSH_HOME=~/.dsh-lab`、web 3082 冒烟）；
4. 依赖声明用**无上界下限** `>=最低已验证版本`（不写精确/带上界范围），并把新 release 记入 `dsh.compatibility.dshReleases`。

### 3.5 测试与验证规范

- 单元测试覆盖纯函数与编排逻辑；**涉及 patch 的必须加"真实组合"测试**——用官方 `applyEntryPatches` + `entryListSchema` 对着随包 patch 文件跑，防止打包/版本因素让行为漂移（`!!js` 表达式要用 `entryListSchema` 解析）。
- 运行时冒烟在 lab 平面做：改完 patch 先 `--dump-config` 看组合结果，再上会话验证；A/B（开/关插件）是归因官方问题与插件问题的唯一可靠手段。
- 反向验证习惯：把关键逻辑故意改坏 → 对应测试必须变红 → 恢复后变绿，证明测试真的在测它。

### 3.6 已知接缝陷阱（写 patch / 替换官方行之前先读）

- **Loader patch 索引范围**：只索引顶层行和 `group: true` 且 `config` 为条目数组的行；**agent-preset 的 `config.plugins` 内部行无法被 patch 定位**（insert 报 `entry ... not found`）。绕行 = 整表替换 preset 行（与 Web 预设编辑器同一机制），代价是副本随 DSH release 逐版本重同步，并加内容测试防漂移。
- **Cordis 服务语义**：`reflect.provide` 同名重复注册抛错；`isolate` 命名空间硬隔离、无回落；`reflect.set` 仅属主 fiber 可写——根服务不能被子上下文"遮蔽"。
- **事件跨 realm**：顶层发出的行事件，preset 隔离 realm 里的监听收不到；需要 `ctx.on(name, fn, { global: true })`。
- **Web 面与 TUI 的 agent 平面不同**：Web 把工具/压缩/委托放进每个 agent-preset 的隔离组（web-app 禁用顶层行、由 preset 挂载），TUI 用顶层组合——"替换官方行"通常要**顶层 + preset 整表两条路径各做一遍**。
- **配置即改即生效**：替换行要自己监听 `settings-update` 之类的事件并 dispose-first 重挂载，首次挂载要 await（命令才会立刻解析到服务）。

### 3.7 结论规范

- 结论注明来源：`docs/<文件>.zh.md`（含版本 tag）或 `packages/<包>/.../<文件>`（含版本）；文档与实现冲突时注明两者并以实现为准。
- 涉及官方行为的用户可见文案，措辞与范围以项目冻结范围文档为准，不扩大承诺。

## 快速命令速查

```powershell
# 最新 DSH 版本
npm view @deepseek-ai/dsh version

# 拉取/更新对应版本源码 + 全套开发者文档
& "$env:USERPROFILE\.dsh\skills\dsh-dev-reference\scripts\refresh-dsh-reference.ps1"

# 单篇文档直取（示例：接缝清单中文版）
curl.exe -s https://raw.githubusercontent.com/deepseek-ai/deepseek-harness/dsh-v0.2.0-rc.2/docs/capability-seams.zh.md

# 两版之间文档/实现改了什么（在参考检出里）
git -C ~/.dsh/reference/deepseek-harness log --oneline dsh-v0.1.7-rc.2..dsh-v0.2.0-rc.2 -- docs packages
```
