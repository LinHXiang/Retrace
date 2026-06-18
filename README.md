# Retrace

[中文](README.zh-Hans.md)

I liked Warp's command history list. When I had to use
a regular terminal it was painful to lose that — then I
realized Maccy's interaction model was exactly what I
wanted. So here it is: a minimal macOS menu bar app that
searches your recent terminal commands.

Retrace supports macOS and records zsh commands through a
small hook installed in `~/.zshrc`.

## Installation

Retrace is available as a signed and notarized Homebrew cask:

```sh
brew tap LinHXiang/tap
brew install --cask linhxiang/tap/retrace
```

## Usage

- Open from the menu bar or press `Shift + Command + T`.
- Reads commands from Retrace's own zsh history file:

  ```text
  ~/Library/Application Support/Retrace/zsh_history
  ```

- Retrace automatically installs a marked zsh integration block
  in `~/.zshrc` when it detects a zsh setup. You can also install
  or copy the block from Preferences.
- Preferences can replace Retrace's history file with the current
  contents of `~/.zsh_history`. This is an overwrite of Retrace's
  own file; your `~/.zsh_history` file is not changed.
- Parses zsh extended history format:

  ```text
  : 1712345678:0;git push origin main
  ```

- Preserves multiline commands from zsh history, including plain
  zsh entries that use trailing `\` line continuations.
- Deduplicates commands and keeps the most recent timestamp.
- Sorts by most recent use.
- Search, keyboard navigation, selected-command preview, `Enter`
  to copy, `Esc` to close.
- Press `Command + P` to pin or unpin the selected command.
  Pinned commands stay at the top of the list.
- Selected command goes to the system clipboard — nothing more.

Retrace does not execute commands, paste into Terminal,
connect to AI services, or read anything other than its own
zsh history file and the one-time/manual import source
`~/.zsh_history`.

## Development

Open `Retrace.xcodeproj` in Xcode and run the `Retrace` scheme.
The app product is named `Retrace`.

To build and install a Release copy to `/Applications`, run:

```sh
scripts/install_release.sh
```

To create a signed, notarized release archive for distribution, run:

```sh
scripts/package_release.sh <version>
```
