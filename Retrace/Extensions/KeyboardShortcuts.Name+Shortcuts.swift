import KeyboardShortcuts

extension KeyboardShortcuts.Name {
  static let popup = Self("popup", default: Shortcut(.t, modifiers: [.command, .shift]))
  static let togglePreview = Self("togglePreview", default: Shortcut(.space, modifiers: [.control]))
}
