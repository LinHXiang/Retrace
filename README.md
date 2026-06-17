# Retrace

I liked Warp's command history list. When I had to use
a regular terminal it was painful to lose that — then I
realized Maccy's interaction model was exactly what I
wanted. So here it is: a minimal macOS menu bar app that
searches your recent terminal commands.

The MVP supports macOS and zsh only.

## Usage

- Open from the menu bar or press `Shift + Command + T`.
- Reads commands from `~/.zsh_history`.
- Parses zsh extended history format:

  ```text
  : 1712345678:0;git push origin main
  ```

- Deduplicates commands and keeps the most recent timestamp.
- Sorts by most recent use.
- Search, keyboard navigation, `Enter` to copy, `Esc` to close.
- Selected command goes to the system clipboard — nothing more.

Retrace does not execute commands, paste into Terminal,
connect to AI services, or read history from anything other
than zsh.

## Development

Open `Retrace.xcodeproj` in Xcode and run the `Retrace` scheme.
The app product is named `Retrace`.

---

[中文](README.zh-Hans.md)
