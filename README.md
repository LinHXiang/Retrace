# Retrace

[中文](README.zh-Hans.md)

I liked Warp's command history list. When I had to use
a regular terminal it was painful to lose that — then I
realized Maccy's interaction model was exactly what I
wanted. So here it is: a minimal macOS menu bar app that
searches your recent terminal commands.

Retrace supports macOS and shell history files from zsh,
bash, and fish.

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

- Deduplicates commands and keeps the most recent timestamp.
- Sorts by most recent use.
- Search, keyboard navigation, `Enter` to copy, `Esc` to close.
- Selected command goes to the system clipboard — nothing more.

Retrace does not execute commands, paste into Terminal,
connect to AI services, or read anything other than the
configured shell history files.

## Development

Open `Retrace.xcodeproj` in Xcode and run the `Retrace` scheme.
The app product is named `Retrace`.
