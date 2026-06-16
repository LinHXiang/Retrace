# Retrace

Retrace is a minimal macOS menu bar app for searching recent terminal commands.

It is based on Retrace, but the data source is terminal command history instead
of clipboard history. The MVP supports macOS and zsh only.

## MVP

- Opens from the menu bar or the global shortcut `Shift + Command + T`.
- Reads commands from `~/.zsh_history`.
- Parses zsh extended history lines:

  ```text
  : 1712345678:0;git push origin main
  ```

- Deduplicates commands and keeps the most recent timestamp for each command.
- Sorts commands by most recent use.
- Supports search, keyboard navigation, `Enter` to copy, and `Esc` to close.
- Copies the selected command to the system clipboard.

Retrace does not execute commands, paste into Terminal, connect to AI services, or
read history from Atuin, bash, fish, Warp, or iTerm.

## Development

Open `Retrace.xcodeproj` in Xcode and run the `Retrace` scheme. The app product is
named `Retrace`.
