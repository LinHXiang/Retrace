import SwiftUI

@Observable
class FooterItem: Equatable, Identifiable, HasVisibility {
  static func == (lhs: FooterItem, rhs: FooterItem) -> Bool {
    return lhs.id == rhs.id
  }

  let id = UUID()

  var title: String
  var shortcuts: [KeyShortcut] = []
  var help: LocalizedStringKey?
  var isSelected: Bool = false
  var isVisible: Bool = true
  var action: () -> Void

  init(
    title: String,
    shortcuts: [KeyShortcut] = [],
    help: LocalizedStringKey? = nil,
    action: @escaping () -> Void
  ) {
    self.title = title
    self.shortcuts = shortcuts
    self.help = help
    self.action = action
  }
}
