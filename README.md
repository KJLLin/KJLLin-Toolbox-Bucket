# KJLLin Toolbox — 稳定版 bucket

KJLLin Toolbox（UniGetUI 改造版）的应用清单。

## 当前内容

| 清单 | 状态 |
|---|---|
| `bucket/ripgrep.json` | ✅ 真实可安装（官方 Release 资源，哈希已核对）—— 用来验证“发现 → 安装 → 更新”整条链路 |
| `bucket/hpcl.json` | ⚠️ 占位：`KJLLin/HPCL` 仓库尚不存在，装不上 |
| `bucket/luogu-export.json` | ⚠️ 占位：哈希是全 0，需替换真实 zip |

## 怎么装

客户端（KJLLin Toolbox）需本机已装 Scoop。没有的话先：

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex
```

然后打开客户端，`toolbox` 源里应该能看到 `ripgrep`，点安装即可。

命令行验证：

```powershell
scoop bucket add toolbox https://github.com/KJLLin/KJLLin-Toolbox
scoop install toolbox/ripgrep
rg --version
```

## 换成自己的应用需要什么

1. 应用仓库建好，打 tag 发 Release，上传 zip
2. 把清单里的 `url` 指向真实 `releases/download/<tag>/<file>.zip`
3. `hash` 换成真实 zip 的 SHA256（`Get-FileHash xxx.zip -Algorithm SHA256`）
4. `bin` 写解压后的 exe 路径
