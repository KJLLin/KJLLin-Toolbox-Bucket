# KJLLin Toolbox — 稳定版 bucket

KJLLin Toolbox（UniGetUI 改造版）的稳定版应用清单。

## 使用

客户端已内置本 bucket：`toolbox` → `https://github.com/KJLLin/KJLLin-Toolbox`。

命令行验证：

```powershell
scoop bucket add toolbox https://github.com/KJLLin/KJLLin-Toolbox
scoop install toolbox/hpcl
```

## 结构

- `bucket/*.json` —— 每个应用一个清单
- 版本号由 GitHub Release 驱动（`checkver` + `autoupdate`）

## 发布新版本

1. 在应用仓库打 tag（例如 `v1.3.0`）并上传 zip 资产
2. 跑 `scoop checkver -u .` 或在 CI 里用 `excavator` 自动提 PR
3. 清单里的 `hash` 必须是真实 zip 的 SHA256

> 当前清单指向的 Release 资产需自行上传，否则安装会 404。
