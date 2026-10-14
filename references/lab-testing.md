# Lab 平面（3082）测试与调试操作手册

运行时冒烟、真实组合验证、浏览器交互测试都在 lab 平面做，绝不碰用户的主平面。本页是完整操作流程与注意事项，§3.5 的验证规范引用本页。

## 1. 平面身份与隔离

- lab = 独立 `DSH_HOME` + 独立 profile + 独立端口，与主平面（`~/.dsh`）**完全隔离**：插件、设置、会话、凭证互不可见。
- 三要素必须同时指定，缺一即污染别的平面：

  ```powershell
  $env:DSH_HOME = "$env:USERPROFILE\.dsh-lab"    # ← 忘设这一行是最危险的失误
  & "$env:APPDATA\npm\dsh.ps1" --profile lab --host 127.0.0.1 --port 3082 --no-open
  ```

- `DSH_HOME` 布局：`llm-deepseek/`（凭证）、`logs/`、`profiles/`、`sessions/`（会话数据）、`storages/`。
- 日志：`$env:USERPROFILE\.dsh-lab\logs\startup-*.log`（每次启动一份，排障先看它）。

## 2. 启动、判活、停止

- **后台承载**：把启动命令放进后台任务（pwsh 后台 job / nohup 等），否则会话结束即被收割。
- **认证入口**：启动成功的唯一标志是 stdout 打印的一行

  ```
  dsh web: http://127.0.0.1:3082/?token=...
  ```

  用这个完整 URL（带 token）在浏览器打开一次，之后 cookie 持久——刷新、开新标签都不需要再带 token。
- **包装器退出 quirk（Windows）**：`dsh.ps1` 拉起 node 后包装器会以 `exit 1` 结束，而真正的宿主 node 进程常驻。**不要用后台 job 的状态判断宿主死活**，判活唯一可靠方法：

  ```powershell
  $c = Get-NetTCPConnection -LocalPort 3082 -State Listen -ErrorAction SilentlyContinue
  if ($c) { "up pid=$($c[0].OwningProcess)" } else { "down" }
  ```

  同理，宿主运行时后台 job 可能显示 completed/exit 1，属正常。
- **停止**（停止后包装 job 才落定）：

  ```powershell
  Stop-Process -Id (Get-NetTCPConnection -LocalPort 3082 -State Listen).OwningProcess -Force
  ```

- 端口被占/起不来：先查 3082 是否残留旧进程，杀干净再启。

## 3. 插件安装与升级（本地构建）

```powershell
Set-Location <插件仓库>
npm pack --ignore-scripts        # 产出 dsh-model-switch-<版本>.tgz（git-ignored，留在仓库根即可）
$env:DSH_HOME = "$env:USERPROFILE\.dsh-lab"
& "$env:APPDATA\npm\dsh.ps1" plugin --profile lab add --force "<仓库>\dsh-model-switch-<版本>.tgz"
```

- 升级 = 重跑 `add --force`（旧版本先被移除）；必须先**停宿主**再装，装完再起宿主。
- peer 依赖 WARN（`Issues with peer dependencies found`）是常态，不是失败。
- 版本核对：设置页插件行显示的版本，或 tarball 文件名。

## 4. 浏览器冒烟（Playwright MCP）

- 导航路径：
  - 设置：侧栏 `设置` 按钮 → 对话框侧栏（通用设置/模型切换/模型/…）→ 目标分区。
  - 选择器：composer 底部模型按钮（`aria-label="选择模型，当前 …"`）→ `role=menu` 摘要菜单 → `模型` menuitem → `role=group` 按供应商分组 → `menuitemradio` 行（`[checked]` 即当前）。
  - 字段：`switch`（即时开关）、`combobox`（下拉）、`button "保存/取消"`。
- **多标签 = 多个独立客户端**：第二标签打开同一会话做切换，用来验证"外部切换面/投影跟随"类行为——本标签不点任何东西，看设置页卡片是否实时跟随。
- **refs 会失效**：每次交互后 a11y ref 重排，截图/操作前先 `browser_find` 拿新 ref；跨轮次直接用文本查找（如 `压缩模型`、`DeepSeek Account`）。
- 已知噪音：console 里插件 404（antigravity/plugin-rpc 类）无害，不用追。
- 页面报"连接中断，正在重试"：宿主挂了或正在重启，按 §2 判活后刷新页面即可（cookie 仍在）。

## 5. 基线纪律（冒烟前记录，冒烟后恢复）

改动前先记录：各能力卡开关态、已存 provider/model 对、供应商组列表、界面语言、当前会话模型（供应商+型号）。

恢复顺序与要点：

1. **组** → 组编辑器 `删除该组`（按钮从禁用变可用即已存；`已保存` 反馈出现）。删组是唯一清空组字段的方式。
2. **能力卡** → 关回开关。注意：**UI 开关 OFF 不会清已存 provider/model 对**（字段留在磁盘上，行为上等于 OFF）——这是设计行为，恢复基线以开关态为准；要清字段需另走配置文件编辑，冒烟不需要。
3. **界面语言** → General → Language 切回原语言。
4. **会话模型** → 选择器切回原供应商/模型。
5. 关掉多余标签页 → 停宿主（§2）→ 后台 job 落定。

## 6. 文档截图

- README 等文档的截图要与**当前版本 UI** 一致（删除/新增卡片后旧截图过期，必须重拍）。
- 流程：语言切 English（General → Language）→ 打开目标设置分区 → 截对话框元素（`browser_take_screenshot`，`scale: css`，type png）→ 复制到 `docs/screenshots/<原文件名>` 同名替换 → 恢复语言与开关状态。
- `.playwright-mcp/` 是 Playwright 的工作目录，**永不入库**（各仓库 .gitignore 已排除；截图拍完主动复制出仓库根再清理临时文件）。

## 7. 陷阱清单

- **lab 会话内的命令执行**：lab 配置了 auto-review 时，会话里模型执行的命令会再被审查调用拦截；凭证缺失（`MISSING_CREDENTIAL`）会让"跑条命令验证"类冒烟在 lab 会话内失败。冒烟脚本从宿主外执行（外部 pwsh），不要依赖 lab 会话内执行。
- **后台 job 的 stderr 噪音**：pwsh 把 git push 等的 stderr 当错误流显示（`NativeCommandError`、exit 1），**看输出正文**判断成败（`a..b main -> main` 出现即推送成功）。
- **auto-review 429/RATE_LIMIT**：宿主自己的审查调用偶发被限流，工具调用会间歇性被拒——等一等重试即可；重试前先用只读手段确认上一次是否其实已生效（避免重复写）。
- **改 patch 后先预检组合**：`dsh --dump-config`（或等价方式）看 loader patch 组合结果，再上会话验证；A/B（开/关插件）是区分"官方问题 vs 插件问题"的唯一可靠手段。
- **判活/停止只认端口**（§2），不认 job 状态。
- **会话树标题 = 首条 prompt 命名的结果**，可直接用于观察命名调用（`session/title`、`session/title-llm-request` 事件的 `route` 字段记录命名所用模型）。

## 8. 通用最小冒烟清单

1. 宿主起来、页面登录、设置目标分区渲染正常（卡片/开关状态与基线一致）。
2. 触发被改行为（选择器切换 / 开关保存 / 组应用）→ 卡片、摘要按预期变化。
3. 跨标签/外部面验证（若该行为声称"任意切换面"）→ 第二标签操作，本标签实时跟随。
4. 失败路径（可模拟时）：写失败只告警不炸切换。
5. 恢复基线（§5）、停宿主、清理临时文件。
