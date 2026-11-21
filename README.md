# KJLLin Toolbox — 稳定版 bucket

KJLLin Toolbox（UniGetUI 改造版）的应用清单。

## 当前内容

| 清单 | 状态 |
|---|---|
| `bucket/hpcl.json` | ✅ **你的应用**：HPCL Launcher 3.17.0，指向 `KJLLin/HPCL-Launcher` 真实 Release，SHA256 已复算比对 |
| `bucket/ripgrep.json` | ✅ 外部样例包，用来对照验证链路 |

## 怎么装

**不用手装 Scoop。** KJLLin Toolbox 安装包收尾时会以当前用户身份、隐藏窗口跑内置的 `EnsureScoop.ps1`：

1. 没有 `scoop` 就装官方版（`get.scoop.sh`）
2. 补 `git`（`scoop bucket add` 需要）
3. 注册 `toolbox` / `toolbox-beta` 两个 bucket

日志在 `%TEMP%\kjllin-toolbox-scoop.log`；任何一步失败都不影响安装成功。
装完打开客户端，首页（Discover）直接就是本源的应用列表。

手动验证：

```powershell
scoop bucket add toolbox https://github.com/KJLLin/KJLLin-Toolbox-Bucket   # 客户端已自动做
scoop install toolbox/hpcl
hpcl
```

## 发布新版本

1. 在 `HPCL-Launcher` 打 tag `v3.18.0` 并发 Release（带 `HPCL-3.18.0.exe` 和 `SHA256SUMS.txt`）
2. 改本仓库 `bucket/hpcl.json` 的 `version` 与 `hash`（哈希从 `SHA256SUMS.txt` 里拿）
3. `autoupdate` 会自动拼 `v$version/HPCL-$version.exe`，所以不用改 URL 模板
