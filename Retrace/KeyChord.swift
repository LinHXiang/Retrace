import AppKit.NSEvent
import KeyboardShortcuts
import Sauce

enum KeyChord: CaseIterable {
  static var previewKey: Key? { Sauce.shared.key(shortcut: .togglePreview) }
  static var previewModifiers: NSEvent.ModifierFlags? { KeyboardShortcuts.Shortcut(name: .togglePreview)?.modifiers }

  case clearSearch
  case deleteOneCharFromSearch
  case deleteLastWordFromSearch
  case ignored
  case moveToNext
  case moveToLast
  case moveToPrevious
  case moveToFirst
  case openPreferences
  case selectCurrentItem
  case close
  case togglePreview
  case unknown

  init(_ event: NSEvent?) {
    guard let event, event.type == .keyDown else {
      self = .unknown
      return
    }

    let modifierFlags = event.modifierFlags
      .intersection(.deviceIndependentFlagsMask)
      .subtracting([.capsLock, .numericPad, .function])
    var key: Key?

    if KeyboardLayout.current.commandSwitchesToQWERTY, modifierFlags.contains(.command) {
      key = Key(QWERTYKeyCode: Int(event.keyCode))
    } else {
      key = Sauce.shared.key(for: Int(event.keyCode))
    }

    guard let key else {
      self = .unknown
      return
    }

    self.init(key, modifierFlags)
  }

  init(_ key: Key, _ modifierFlags: NSEvent.ModifierFlags) {
    if let chord = Self.editingChord(key, modifierFlags)
      ?? Self.downwardChord(key, modifierFlags)
      ?? Self.upwardChord(key, modifierFlags)
      ?? Self.actionChord(key, modifierFlags) {
      self = chord
      return
    }

    if !modifierFlags.isDisjoint(with: [.command, .control, .option]) {
      self = .ignored
      return
    }

    self = .unknown
  }

  private static func editingChord(_ key: Key, _ modifierFlags: NSEvent.ModifierFlags) -> KeyChord? {
    switch (key, modifierFlags) {
    case (.u, [.control]):
      return .clearSearch
    case (.h, [.control]):
      return .deleteOneCharFromSearch
    case (.w, [.control]):
      return .deleteLastWordFromSearch
    default:
      return nil
    }
  }

  private static func downwardChord(_ key: Key, _ modifierFlags: NSEvent.ModifierFlags) -> KeyChord? {
    switch (key, modifierFlags) {
    case (.downArrow, [.shift]),
         (.n, [.control, .shift]):
      return .moveToNext
    case (.downArrow, []),
         (.n, [.control]),
         (.j, [.control]):
      return .moveToNext
    case (.downArrow, [.command, .shift]),
         (.downArrow, [.option, .shift]),
         (.n, [.control, .option, .shift]):
      return .moveToLast
    case (.downArrow, _) where modifierFlags.contains(.command) || modifierFlags.contains(.option),
         (.n, [.control, .option]),
         (.pageDown, []):
      return .moveToLast
    default:
      return nil
    }
  }

  private static func upwardChord(_ key: Key, _ modifierFlags: NSEvent.ModifierFlags) -> KeyChord? {
    switch (key, modifierFlags) {
    case (.upArrow, [.shift]),
         (.p, [.control, .shift]):
      return .moveToPrevious
    case (.upArrow, []),
         (.p, [.control]),
         (.k, [.control]):
      return .moveToPrevious
    case (.upArrow, [.command, .shift]),
         (.upArrow, [.option, .shift]),
         (.p, [.control, .option, .shift]):
      return .moveToFirst
    case (.upArrow, _) where modifierFlags.contains(.command) || modifierFlags.contains(.option),
         (.p, [.control, .option]),
         (.pageUp, []):
      return .moveToFirst
    default:
      return nil
    }
  }

  private static func actionChord(_ key: Key, _ modifierFlags: NSEvent.ModifierFlags) -> KeyChord? {
    switch (key, modifierFlags) {
    case (.comma, [.command]):
      return .openPreferences
    case (.return, _),
         (.keypadEnter, _):
      return .selectCurrentItem
    case (.escape, _):
      return .close
    case (KeyChord.previewKey, KeyChord.previewModifiers):
      return .togglePreview
    default:
      return nil
    }
  }
}
