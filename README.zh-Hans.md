# Retrace

我很喜欢 Warp 里的历史命令列表。每次换回普通终端都觉得少了点什么——
后来发现 Maccy 的交互方式正好满足我的需求。于是就做了这个：一个轻量
的 macOS 菜单栏应用，用来搜索最近敲过的终端命令。

MVP 仅支持 macOS 和 zsh。

## 用法

- 从菜单栏打开，或按 `Shift + Command + T`。
- 读取 `~/.zsh_history`。
- 解析 zsh extended history 格式：

  ```text
  : 1712345678:0;git push origin main
  ```

- 命令去重，保留最近一次使用的时间戳。
- 按最近使用时间排序。
- 支持搜索、键盘导航、`Enter` 复制、`Esc` 关闭。
- 选中的命令复制到剪贴板——仅此而已。

Retrace 不会执行命令、不会粘贴到终端、不会接入 AI 服务，
也不会从 zsh 以外的任何来源读取历史。

## 开发

在 Xcode 中打开 `Retrace.xcodeproj`，运行 `Retrace` scheme。
产品名即 `Retrace`。

---

[English](README.md)
