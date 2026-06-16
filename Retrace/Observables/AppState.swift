import AppKit
import Defaults
import Foundation
import Settings
import SwiftUI

@Observable
class AppState {
  static let shared = AppState(history: History.shared, footer: Footer())

  var appDelegate: AppDelegate?
  var popup: Popup
  var history: History
  var footer: Footer
  var navigator: NavigationManager
  var preview: SlideoutController

  var searchVisible: Bool {
    if !Defaults[.showSearch] { return false }
    switch Defaults[.searchVisibility] {
    case .always: return true
    case .duringSearch: return !history.searchQuery.isEmpty
    }
  }

  var menuBarCommandText: String {
    var title = history.visibleItems.first?.text.shortened(to: 100)
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    title.unicodeScalars.removeAll(where: CharacterSet.newlines.contains)
    return title.shortened(to: 20)
  }

  private let about = About()
  private var settingsWindowController: SettingsWindowController?

  init(history: History, footer: Footer) {
    self.history = history
    self.footer = footer
    popup = Popup()
    navigator = NavigationManager(history: history, footer: footer)
    preview = SlideoutController(
      onContentResize: { contentWidth in
        Defaults[.windowSize].width = contentWidth
      },
      onSlideoutResize: { previewWidth in
        Defaults[.previewWidth] = previewWidth
      })
    preview.contentWidth = Defaults[.windowSize].width
    preview.slideoutWidth = Defaults[.previewWidth]
  }

  @MainActor
  func select() {
    if let item = navigator.selectedHistoryItem {
      history.select(item)
    } else if let item = footer.selectedItem {
      item.action()
    } else {
      Clipboard.shared.copy(history.searchQuery)
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
        },
        Settings.Pane(
          identifier: Settings.PaneIdentifier.appearance,
          title: NSLocalizedString("Title", tableName: "AppearanceSettings", comment: ""),
          toolbarIcon: NSImage.paintpalette!
        ) {
          AppearanceSettingsPane()
        }
      ]
    )
  }

  func quit() {
    NSApp.terminate(self)
  }
}
