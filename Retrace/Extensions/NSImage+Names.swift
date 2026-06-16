import Cocoa

extension NSImage {
  static let gearshape = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "gearshape")
  static let paintpalette = NSImage(systemSymbolName: "paintpalette", accessibilityDescription: "paintpalette")
}

extension NSImage.Name {
  static let clipboard = NSImage.Name("clipboard.fill")
  static let retraceStatusBar = NSImage.Name("StatusBarMenuImage")
  static let scissors = NSImage.Name("scissors")
  static let paperclip = NSImage.Name("paperclip")
}
