import AppKit
import Defaults
import Foundation
import Settings
import SwiftUI

@Observable
class AppState {
  static let shared = AppState(history: CommandHistory.shared, footer: Footer())

  var appDelegate: AppDelegate?
  var popup: Popup
  var history: CommandHistory
  var footer: Footer
  var navigator: NavigationManager

  var searchVisible: Bool {
    if !Defaults[.showSearch] { return false }
    switch Defaults[.searchVisibility] {
    case .always: return true
    case .duringSearch: return !history.searchQuery.isEmpty
    }
  }

  var menuBarCommandText: String {
    var title = history.visibleItems.first?.title.shortened(to: 100)
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    title.unicodeScalars.removeAll(where: CharacterSet.newlines.contains)
    return title.shortened(to: 20)
  }

  private let about = About()
  private var settingsWindowController: SettingsWindowController?

  init(history: CommandHistory, footer: Footer) {
    self.history = history
    self.footer = footer
    popup = Popup()
    navigator = NavigationManager(history: history, footer: footer)
  }

  @MainActor
  func select() {
    if let item = navigator.selectedCommandItem {
      history.select(item)
    } else if let item = footer.selectedItem {
      item.action()
    } else {
      CommandPasteboard.shared.copy(history.searchQuery)
      history.searchQuery = ""
    }
  }

  func openAbout() {
    about.openAbout(nil)
  }

  @MainActor
  func openPreferences() {
    if settingsWindowController == nil {
      settingsWindowController = makeSettingsWindowController()
    }
    settingsWindowController?.show()
    settingsWindowController?.window?.orderFrontRegardless()
  }

  private func makeSettingsWindowController() -> SettingsWindowController {
    SettingsWindowController(
      panes: [
        Settings.Pane(
          identifier: Settings.PaneIdentifier.general,
          title: NSLocalizedString("Title", tableName: "GeneralSettings", comment: ""),
          toolbarIcon: NSImage.gearshape!
        ) {
          GeneralSettingsPane()
            .font(AppFont.regular())
        },
        Settings.Pane(
          identifier: Settings.PaneIdentifier.appearance,
          title: NSLocalizedString("Title", tableName: "AppearanceSettings", comment: ""),
          toolbarIcon: NSImage.paintpalette!
        ) {
          AppearanceSettingsPane()
            .font(AppFont.regular())
        }
      ]
    )
  }

  func quit() {
    NSApp.terminate(self)
  }
}
