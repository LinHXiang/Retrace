import AppKit

class Clipboard {
  static let shared = Clipboard()

  private let pasteboard = NSPasteboard.general

  @MainActor
  func copy(_ string: String) {
    pasteboard.clearContents()
    pasteboard.setString(string, forType: .string)
  }

  @MainActor
  func copy(_ item: CommandHistoryItem?) {
    guard let item, let text = item.text else { return }
    copy(text)
  }
}
