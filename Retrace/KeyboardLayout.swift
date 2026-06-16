import Carbon
import Sauce

class KeyboardLayout {
  static var current: KeyboardLayout { KeyboardLayout() }

  // Dvorak - QWERTY Command and bépo 1.1 - Azerty Command layouts switch to QWERTY.
  var commandSwitchesToQWERTY: Bool { localizedName.hasSuffix("⌘") }

  var localizedName: String {
    if let value = TISGetInputSourceProperty(inputSource, kTISPropertyLocalizedName) {
      return Unmanaged<CFString>.fromOpaque(value).takeUnretainedValue() as String
    } else {
      return ""
    }
  }

  private var inputSource: TISInputSource!

  init() {
    inputSource = TISCopyCurrentKeyboardLayoutInputSource().takeUnretainedValue()
  }
}
