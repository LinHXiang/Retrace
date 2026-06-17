# Retrace

[中文](README.zh-Hans.md)

I liked Warp's command history list. When I had to use
a regular terminal it was painful to lose that — then I
realized Maccy's interaction model was exactly what I
wanted. So here it is: a minimal macOS menu bar app that
searches your recent terminal commands.

Retrace supports macOS and shell history files from zsh,
bash, and fish.

## Installation

Retrace is currently available as a prerelease Homebrew cask:

```sh
brew tap LinHXiang/tap
brew install --cask linhxiang/tap/retrace
```

The current `1.0.0-rc2` build is intended for testing the
distribution flow and is not notarized yet. A notarized stable
release will replace it once Apple's notarization completes.

## Usage

- Open from the menu bar or press `Shift + Command + T`.
- Reads commands from configured shell history files.
- Default sources:

  ```text
  ~/.zsh_history
  ~/.bash_history
  ~/.local/share/fish/fish_history
  ```

- Manage history sources in Preferences. You can enable,
  disable, add, remove, or change the parser for a source.
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
connect to AI services, or read anything other than the
configured shell history files.

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
