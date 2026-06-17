import AppKit
import CoreText
import SwiftUI

enum AppFont {
  static let regularName = "JetBrainsMono-Regular"
  static let boldName = "JetBrainsMono-Bold"
  static let defaultSize = NSFont.systemFontSize + 2

  static func regular(size: CGFloat = defaultSize) -> Font {
    .custom(regularName, size: size)
  }

  static func bold(size: CGFloat = defaultSize) -> Font {
    .custom(boldName, size: size)
  }

  static func registerBundledFonts() {
    [
      "JetBrainsMono-Regular",
      "JetBrainsMono-Bold",
    ].forEach(registerFont)
  }

  private static func registerFont(named name: String) {
    guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else {
      return
    }

    _ = CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
  }
}
