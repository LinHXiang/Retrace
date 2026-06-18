# zsh 集成命令记录

## 背景

Retrace 的命令历史记录只支持 zsh。

读取 `~/.zsh_history` 对普通 zsh shell 有效，但有一个实际延迟问题：
zsh 可能把历史记录保存在内存里，只在 shell 退出时写入文件，除非用户开启
`INC_APPEND_HISTORY` 这类选项。

对长时间运行的终端会话来说，用户已经执行过的命令，Retrace 仍然可能暂时读
不到。

## 目标

在不依赖 `~/.zsh_history` 刷新时机的前提下记录 zsh 命令。

Retrace 应该自动把一段 zsh 集成 block 写入 `~/.zshrc`。这段 block 使用 zsh
hook，把用户执行过的命令追加写入 Retrace 自己管理的历史文件。
Retrace 再把这个文件作为主要命令历史来源读取。

## 非目标

- 不通过 Accessibility 截取终端 UI 文本。
- 不包装或替换用户的终端。
- 不要求 Retrace.app 正在运行时才能记录命令。
- 不在 shell hook 里直接写 sqlite。
- 不在这个设计里支持 bash、fish 或其他 shell 的实时命令记录。

## 方案

启动时检测到用户使用 zsh 且 `~/.zshrc` 尚未包含 Retrace 标记 block 时，
自动安装一个带标记的 zsh 集成 block。

这个 block 必须可以重复安装：不存在时追加，已存在时只替换标记范围内的内容。

```zsh
# >>> Retrace zsh integration >>>
autoload -Uz add-zsh-hook
zmodload zsh/datetime 2>/dev/null

_retrace_preexec() {
  local dir="$HOME/Library/Application Support/Retrace"
  mkdir -p "$dir" || return
  print -r -- ": ${EPOCHSECONDS}:0;$1" >> "$dir/zsh_history"
}

add-zsh-hook preexec _retrace_preexec
# <<< Retrace zsh integration <<<
```

Retrace 自有历史文件路径：

```text
~/Library/Application Support/Retrace/zsh_history
```

文件使用 zsh extended history 格式：

```text
: 1712345678:0;git status
```

这样可以复用 Retrace 现有的 zsh parser。shell hook 保持很小，只做追加写入，
并且不依赖 app 进程状态。

## 为什么不在 hook 里写 sqlite

Maccy 可以直接把剪贴板历史写入 sqlite，是因为剪贴板事件发生在 app 进程里。
Retrace 的命令事件发生在用户的 shell 进程里。

如果把 sqlite 写入放进 zsh hook，就等于把数据库锁、schema 迁移、二进制可用
性、失败处理和并发问题放进用户每次执行命令的路径里。这不是复杂性应该待的
地方。

更好的分层是：

1. zsh hook 写 append-only 的 Retrace 自有历史文件。
2. Retrace 用现有 parser 读取这个文件。
3. 如果之后需要更快搜索或更多元数据，由 app 进程把这个文件导入 sqlite。

append-only 文件是事实源。sqlite 如果加入，只是 app 自己的缓存或索引。

## 数据流

```text
zsh preexec hook
  -> ~/Library/Application Support/Retrace/zsh_history
  -> Retrace history loader / file watcher
  -> existing parseZsh path
  -> search index / displayed command list
  -> optional app-owned sqlite index
```

## 默认历史来源

内置默认命令历史来源只保留 Retrace 自己的 zsh 记录文件：

```text
~/Library/Application Support/Retrace/zsh_history
```

Retrace 不再把 `~/.zsh_history`、bash history、fish history 或用户手动添加的
其他文件作为命令来源。`~/.zsh_history` 只可以用于启动时判断用户是否可能在用
zsh，从而决定是否自动安装 zsh 集成；它不是数据源。

为了让首次使用不显得完全空白，Retrace 可以在首次启动时尝试一次性导入：如果
`~/Library/Application Support/Retrace/zsh_history` 不存在或为空，并且用户的
`~/.zsh_history` 可读，就把 `~/.zsh_history` 的当前内容复制到 Retrace 自有文件。
尝试完成后写入本地标记，后续启动不再重复导入，也不继续读取 `~/.zsh_history`。

因此，只有安装 zsh 集成后，Retrace 才能正常记录并展示新命令。没有安装 zsh
集成时，用户看不到命令记录，这是预期行为。

## 启动检测

Retrace 启动时应该检查 zsh 集成是否已安装。

只有同时满足以下条件时，才自动安装：

1. 用户登录 shell 是 zsh，或者 Retrace 能以其他方式判断用户使用 zsh。
2. `~/.zshrc` 不包含 Retrace 标记 block。

安装成功和失败都通过通知反馈。自动安装失败最多重试 3 次，之后不再在启动时反复
打扰用户；用户仍然可以在 Preferences 里手动重新安装或复制 block。

从旧版本升级时，如果用户曾经对安装提示选择过 `Don't Ask Again`，Retrace 会把它
迁移成禁用自动安装，不会在升级后自动修改 `~/.zshrc`。
旧版本的 `Not Now` 冷却期不再保留；升级后按新的自动安装规则执行。

## 安装体验

在 `Preferences > Command history` 提供：

- Install zsh integration
- Copy zsh integration
- Clear Retrace history
- Delete Retrace history file

这里不再提供添加、移除、选择或禁用 history source 的 UI。命令来源固定为：

```text
~/Library/Application Support/Retrace/zsh_history
```

自动安装和 `Install zsh integration` 都应该：

1. 如果 `~/.zshrc` 不存在，创建它。
2. 如果没有 Retrace block，追加一个带标记的 block。
3. 如果已经有 Retrace block，只替换标记范围内的 block。
4. 尽量逐字节保留 `~/.zshrc` 里其他用户内容。
5. 自动安装失败时展示错误；手动安装展示成功或失败结果。

`Copy zsh integration` 复制同一段 block，给想手动安装的用户使用。

## 记录语义

使用 `preexec`。

`preexec` 在用户按下 Return 之后、命令实际执行之前触发。因此失败的命令、
不存在的命令、退出码非零的命令都会被记录。

对命令历史搜索来说，这是可接受且通常更符合预期的：用户确实输入并尝试执行
过这条命令。

第一版不要尝试只记录成功命令。那需要把 `preexec` 和 `precmd` 配对，并跟踪
退出状态，会引入状态和边界情况。

## 边界情况

- 多行命令：zsh 会把完整命令传给 `preexec`；`print -r --` 会保留内容。现有
  zsh parser 已经支持 extended entry 后面跟 continuation lines。
- Application Support 目录不存在：hook 使用 `mkdir -p` 创建。
- Retrace 未运行：仍然可以记录，因为 hook 写入的是文件。
- 多个终端：多个 shell 追加写同一个文件。对这个产品来说，短行追加预计足够。
  如果之后观察到损坏，再加轻量锁。
- 已存在同名 hook：使用 Retrace 前缀函数名，并通过标记 block 替换避免重复
  安装。
- 用户删除 block：如果 Retrace 已经观察到集成安装过，后续启动不再自动补回。
  用户仍可在 Preferences 里手动重新安装。
- 自动安装持续失败：最多自动尝试 3 次，避免每次启动都产生失败通知。

## 验收标准

1. Retrace 命令历史记录被文档化并实现为 zsh-only。
2. 内置默认历史来源只包含
   `~/Library/Application Support/Retrace/zsh_history`。
3. app 启动时检查是否应该自动安装 zsh 集成。
4. 自动安装只对疑似 zsh 用户执行，且要求用户没有已安装 Retrace block，也没有
   被 Retrace 记录为曾经安装过集成。
5. Preferences 暴露明确的 `Install zsh integration` 操作，用于手动重新安装。
6. 如果 `~/.zshrc` 不存在，安装流程会创建它。
7. 如果 `~/.zshrc` 存在但没有 Retrace block，安装流程只追加一个标记 block。
8. 如果 `~/.zshrc` 已有 Retrace block，安装流程替换该 block，而不是追加重复
    block。
9. 标记 block 外的用户内容被保留。
10. 安装后的 hook 会把命令写入
    `~/Library/Application Support/Retrace/zsh_history`。
11. 新执行的 zsh 命令会在 shell 退出前出现在 Retrace 自有历史文件里。
12. Retrace 会把自有历史文件作为 zsh source 读取。
13. 首次启动可以把现有 `~/.zsh_history` 复制到 Retrace 自有历史文件，但后续
    不再读取 `~/.zsh_history`。
14. zsh hook 不调用 sqlite、IPC、URL scheme 或 app 专用通知机制。
15. 构建通过：

    ```sh
    xcodebuild -project Retrace.xcodeproj -scheme Retrace \
      -destination 'platform=macOS' build
    ```

## 建议测试

- 单元测试 block 替换逻辑：
  - 空 `.zshrc`
  - 没有 Retrace block 的 `.zshrc`
  - 有旧 Retrace block 的 `.zshrc`
  - 没有末尾换行的 `.zshrc`
- 单元测试 `HistorySource.defaultSources` 只包含 Retrace 自有 zsh 文件，且不包含
  `~/.zsh_history`、bash 或 fish 默认项。
- 单元测试自动安装条件：
  - 疑似 zsh 用户且没有 block
  - 已存在 Retrace block
  - 曾安装过但 block 已缺失
- 单元测试旧 bash/fish 默认来源的迁移或重置行为。
- 单元测试首次导入 `~/.zsh_history`：目标不存在、目标为空、目标已有内容、源不
  存在。
- 单元测试以 zsh extended history 格式写入的多行命令能被解析成单条命令。
- 用临时 zsh 配置做手工测试：

  ```sh
  ZDOTDIR=/tmp/retrace-zdotdir zsh
  ```

  然后执行一条命令，确认 Retrace 自有历史文件会立刻收到 extended-history
  entry。

## 后续工作

如果 Retrace 之后需要更丰富的元数据，或者需要对大量命令做更快搜索，可以加入
app 自有 sqlite 索引。zsh hook 仍然只写 append-only 历史文件，由 app 进程把
文件导入 sqlite。

潜在 sqlite 表：

```sql
CREATE TABLE commands (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  shell TEXT NOT NULL,
  command TEXT NOT NULL,
  cwd TEXT,
  created_at INTEGER NOT NULL
);
```

不要让 sqlite 成为 shell hook 的一部分。
