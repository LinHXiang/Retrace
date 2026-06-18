# Retrace

我很喜欢 Warp 里的历史命令列表。每次换回普通终端都觉得少了点什么——
后来发现 Maccy 的交互方式正好满足我的需求。于是就做了这个：一个轻量
的 macOS 菜单栏应用，用来搜索最近敲过的终端命令。

Retrace 支持 macOS，并通过安装在 `~/.zshrc` 里的轻量 hook 记录 zsh 命令。

## 安装

Retrace 目前可以通过已签名并完成 Apple 公证的 Homebrew cask 安装：

```sh
brew tap LinHXiang/tap
brew install --cask linhxiang/tap/retrace
```

## 用法

- 从菜单栏打开，或按 `Shift + Command + T`。
- 读取 Retrace 自己管理的 zsh 历史文件：

  ```text
  ~/Library/Application Support/Retrace/zsh_history
  ```

- 检测到 zsh 环境时，Retrace 会自动向 `~/.zshrc` 安装一段带标记的 zsh 集成
  block。也可以在“偏好设置 > 集成”中手动安装。
- “偏好设置 > 通用”里可以用当前 `~/.zsh_history` 覆盖 Retrace 自己的历史文件。
  这个操作覆盖的是 Retrace 文件，不会修改 `~/.zsh_history`。
- 解析 zsh extended history 格式：

  ```text
  : 1712345678:0;git push origin main
  ```

- 保留 zsh history 里的多行命令，包括 plain zsh 中使用行尾 `\`
  续行的命令。
- 命令去重，保留最近一次使用的时间戳。
- 按最近使用时间排序。
- 支持搜索、键盘导航、选中命令预览、`Enter` 复制、`Esc` 关闭。
- 按 `Command + P` 可以固定或取消固定当前选中命令；固定命令会显示在列表顶部。
- 选中的命令复制到剪贴板——仅此而已。

Retrace 不会执行命令、不会粘贴到终端、不会接入 AI 服务，
也不会读取 Retrace 自己的 zsh 历史文件和一次性/手动导入来源
`~/.zsh_history` 以外的内容。

## 开发

在 Xcode 中打开 `Retrace.xcodeproj`，运行 `Retrace` scheme。
产品名即 `Retrace`。

如需构建 Release 版本并安装到 `/Applications`：

```sh
scripts/install_release.sh
```

如需生成用于分发的签名、公证发布包：

```sh
scripts/package_release.sh <version>
```

---

[English](README.md)
