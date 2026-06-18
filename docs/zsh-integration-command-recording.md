# zsh Integration Command Recording

## Background

Retrace currently reads configured shell history files such as
`~/.zsh_history`. That works for normal shells, but it has a real latency
problem: zsh may keep history in memory and write it only when the shell exits,
unless the user enables options such as `INC_APPEND_HISTORY`.

For terminals with long-lived sessions, this means Retrace can miss recent
commands even though the user has already executed them.

## Goal

Record zsh commands without depending on `~/.zsh_history`.

Retrace should install an explicit zsh integration block into `~/.zshrc`.
That block should use zsh hooks to append executed commands into a Retrace-owned
history file under Application Support. Retrace then reads that file as one of
its history sources.

## Non-Goals

- Do not silently modify user shell configuration.
- Do not intercept terminal UI text through Accessibility.
- Do not wrap or replace the user's terminal.
- Do not require Retrace.app to be running for command recording to work.
- Do not write sqlite directly from the shell hook.
- Do not remove support for existing shell history files.

## Proposed Design

Install a marked zsh integration block into `~/.zshrc` only after explicit user
confirmation.

The block should be idempotent:

```zsh
# >>> Retrace zsh integration >>>
autoload -Uz add-zsh-hook

_retrace_preexec() {
  local dir="$HOME/Library/Application Support/Retrace"
  mkdir -p "$dir"
  print -r -- ": $EPOCHSECONDS:0;$1" >> "$dir/zsh_history"
}

add-zsh-hook preexec _retrace_preexec
# <<< Retrace zsh integration <<<
```

The private history file is:

```text
~/Library/Application Support/Retrace/zsh_history
```

The file uses zsh extended history format:

```text
: 1712345678:0;git status
```

This deliberately reuses the existing zsh parser in Retrace. The shell hook
stays small, append-only, and independent of app process state.

## Why Not sqlite in the Hook

Maccy can write clipboard history into sqlite directly because the app process
receives clipboard events. Retrace's command events originate inside shell
processes.

Putting sqlite writes in the zsh hook would put database locking, migrations,
binary availability, and failure handling into the user's command execution
path. That is the wrong place for complexity.

The better split is:

1. zsh hook writes an append-only Retrace-owned history file.
2. Retrace reads that file directly using the existing parser.
3. If search scale or metadata needs grow, Retrace can later import that file
   into sqlite from the app process.

## Data Flow

```text
zsh preexec hook
  -> ~/Library/Application Support/Retrace/zsh_history
  -> Retrace history loader
  -> existing parseZsh path
  -> search index / displayed command list
```

## Default History Sources

Add the Retrace-owned zsh file before the user's normal zsh history:

```text
~/Library/Application Support/Retrace/zsh_history
~/.zsh_history
~/.bash_history
~/.local/share/fish/fish_history
```

Keeping `~/.zsh_history` preserves backwards compatibility and existing user
expectations.

## Installation UX

In Preferences > Command history, provide:

- Install zsh integration
- Copy zsh integration

`Install zsh integration` should:

1. Show a confirmation dialog.
2. Create `~/.zshrc` if it does not exist.
3. Append the marked block if it is missing.
4. Replace only the marked block if it already exists.
5. Preserve all other `~/.zshrc` content byte-for-byte where possible.
6. Show success or failure.

`Copy zsh integration` should copy the same marked block for users who prefer
manual installation.

## Recording Semantics

Use `preexec`.

`preexec` records a command after the user presses Return and before the command
is executed. That means commands that fail, commands that are not found, and
commands that exit non-zero are still recorded.

For command history search, this is acceptable and usually desirable: the user
typed and attempted the command.

Do not attempt to record only successful commands in the first version. That
requires pairing `preexec` with `precmd` and tracking exit status, which adds
state and edge cases.

## Edge Cases

- Multiline commands: zsh passes the complete command to `preexec`; writing it
  with `print -r --` preserves content. The existing zsh parser already handles
  extended entries followed by continuation lines.
- Missing Application Support directory: hook creates it with `mkdir -p`.
- Retrace not running: recording still works because the hook writes to a file.
- Multiple terminals: each shell appends to the same file. Appends of short
  lines are expected to be sufficient for this product. If corruption is later
  observed, add a lightweight lock.
- Existing hook with same function name: use a Retrace-prefixed function name
  and marked block replacement to avoid duplicate installs.
- User removes the block: Retrace should not reinstall it without another
  explicit action.

## Acceptance Criteria

1. Preferences exposes an explicit `Install zsh integration` action.
2. Clicking install asks for confirmation before modifying `~/.zshrc`.
3. If `~/.zshrc` does not exist, installing creates it.
4. If `~/.zshrc` exists without the Retrace block, installing appends exactly
   one marked block.
5. If `~/.zshrc` already contains the Retrace block, installing replaces that
   block instead of appending a duplicate.
6. User content outside the marked block is preserved.
7. The installed hook writes commands to
   `~/Library/Application Support/Retrace/zsh_history`.
8. A newly executed zsh command appears in the Retrace-owned history file before
   the shell exits.
9. Retrace reads the Retrace-owned history file as a zsh source.
10. Existing configured history sources still work.
11. Existing `~/.zsh_history` support is not removed.
12. Build succeeds with `xcodebuild -project Retrace.xcodeproj -scheme Retrace
    -destination 'platform=macOS' build`.

## Suggested Tests

- Unit test the block replacement logic with:
  - empty `.zshrc`
  - `.zshrc` without a Retrace block
  - `.zshrc` with an old Retrace block
  - `.zshrc` without trailing newline
- Unit test that `HistorySource.defaultSources` includes the Retrace-owned
  zsh file.
- Manual test with a temporary zsh config:

  ```sh
  ZDOTDIR=/tmp/retrace-zdotdir zsh
  ```

  Then run a command and verify that the Retrace-owned history file receives an
  extended-history entry immediately.

## Future Work

If Retrace later needs richer metadata or faster search over large datasets,
add an app-owned sqlite index. The zsh hook should still write the append-only
history file, and the app should import from that file into sqlite.

Potential sqlite table:

```sql
CREATE TABLE commands (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  shell TEXT NOT NULL,
  command TEXT NOT NULL,
  cwd TEXT,
  created_at INTEGER NOT NULL
);
```

Do not make sqlite part of the shell hook.
