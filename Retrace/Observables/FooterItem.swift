import SwiftUI

@Observable
class FooterItem: Equatable, Identifiable, HasVisibility {
  static func == (lhs: FooterItem, rhs: FooterItem) -> Bool {
    return lhs.id == rhs.id
  }

  let id = UUID()
  let actionID: String?

  var title: String
  var shortcuts: [KeyShortcut] = []
  var help: LocalizedStringKey?
  var isSelected: Bool = false
  var isVisible: Bool = true
  var action: () -> Void

  init(
    actionID: String? = nil,
    title: String,
    shortcuts: [KeyShortcut] = [],
    help: LocalizedStringKey? = nil,
    isVisible: Bool = true,
    action: @escaping () -> Void
  ) {
    self.actionID = actionID
    self.title = title
    self.shortcuts = shortcuts
    self.help = help
    self.isVisible = isVisible
    self.action = action
  }
}
