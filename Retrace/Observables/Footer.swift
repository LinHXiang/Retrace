import SwiftUI

@Observable
class Footer: ItemsContainer {
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
        title: "sync_existing_history",
        help: "sync_existing_history_tooltip",
        isVisible: ZshIntegration.userHistoryHasContent()
      ) {
        ZshIntegrationUI.syncUserHistory()
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
    guard let item = items.first(where: { $0.title == "sync_existing_history" }) else { return }

    item.isVisible = ZshIntegration.userHistoryHasContent()
  }
}
