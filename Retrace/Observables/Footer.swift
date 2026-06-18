import SwiftUI

@Observable
class Footer: ItemsContainer {
  private static let replaceHistoryItemID = "replace-history"

  var items: [FooterItem] = []

  var selectedItem: FooterItem? {
    willSet {
      selectedItem?.isSelected = false
      newValue?.isSelected = true
    }
  }

  init() {
    items = [
      FooterItem(
        title: "preferences",
        shortcuts: [KeyShortcut(key: .comma)]
      ) {
        Task { @MainActor in
          AppState.shared.openPreferences()
        }
      },
      FooterItem(
        actionID: Self.replaceHistoryItemID,
        title: "replace_with_local_shell_history",
        help: "replace_with_local_shell_history_tooltip",
        isVisible: ZshIntegration.userHistoryHasContent()
      ) {
        ZshIntegrationUI.replaceRecordedHistoryWithUserHistory()
        AppState.shared.footer.refreshHistoryActions()
      },
      FooterItem(
        title: "about",
        help: "about_tooltip"
      ) {
        AppState.shared.openAbout()
      },
      FooterItem(
        title: "quit",
        shortcuts: [KeyShortcut(key: .q)],
        help: "quit_tooltip"
      ) {
        AppState.shared.quit()
      }
    ]
  }

  func refreshHistoryActions() {
    guard let item = items.first(where: { $0.actionID == Self.replaceHistoryItemID }) else { return }

    item.isVisible = ZshIntegration.userHistoryHasContent()
  }
}
