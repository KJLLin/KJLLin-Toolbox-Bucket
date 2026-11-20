# KJLLin Toolbox — 稳定版 bucket

KJLLin Toolbox（UniGetUI 改造版）的应用清单。

## 当前内容

| 清单 | 状态 |
|---|---|
| `bucket/hpcl.json` | ✅ **你的应用**：HPCL Launcher 3.17.0，指向 `KJLLin/HPCL-Launcher` 真实 Release，SHA256 已复算比对 |
| `bucket/ripgrep.json` | ✅ 外部样例包，用来对照验证链路 |

## 怎么装

客户端（KJLLin Toolbox）需本机已装 Scoop。没有的话先：

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex
```

然后打开客户端，`toolbox` 源里应该能看到 `hpcl`，点安装即可（HPCL 需要 Java 17+）。

命令行验证：

```powershell
scoop bucket add toolbox https://github.com/KJLLin/KJLLin-Toolbox
scoop install toolbox/hpcl
hpcl
```

## 发布新版本

1. 在 `HPCL-Launcher` 打 tag `v3.18.0` 并发 Release（带 `HPCL-3.18.0.exe` 和 `SHA256SUMS.txt`）
2. 改本仓库 `bucket/hpcl.json` 的 `version` 与 `hash`（哈希从 `SHA256SUMS.txt` 里拿）
3. `autoupdate` 会自动拼 `v$version/HPCL-$version.exe`，所以不用改 URL 模板
