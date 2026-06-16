import AppKit.NSEvent

// https://github.com/sindresorhus/KeyboardShortcuts/blob/e6b60117ec266e1e5d059f7f34815144f9762b36/Sources/KeyboardShortcuts/Utilities.swift#L308-L342
extension NSEvent.ModifierFlags {
  var description: String {
    var description = ""

    if contains(.control) {
      description += "⌃"
    }

    if contains(.option) {
      description += "⌥"
    }

    if contains(.shift) {
      description += "⇧"
    }

    if contains(.command) {
      description += "⌘"
    }

    if contains(.function) {
      description += "🌐\u{FE0E}"
    }

    return description
  }
}
