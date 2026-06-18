import AppKit
import Defaults
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
  var panel: FloatingPanel<ContentView>!

  @objc
  private lazy var statusItem: NSStatusItem = {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    statusItem.behavior = .removalAllowed
    statusItem.button?.action = #selector(performStatusItemClick)
    statusItem.button?.image = NSImage(named: .retraceStatusBar)
    statusItem.button?.imagePosition = .imageLeft
    statusItem.button?.target = self
    return statusItem
  }()

  private var statusItemVisibilityObserver: NSKeyValueObservation?

  func applicationWillFinishLaunching(_ notification: Notification) {
    AppFont.registerBundledFonts()
    migrateHistorySourcesToAppOwnedZshOnly()
    importUserZshHistoryIfNeeded()

    // Bridge FloatingPanel via AppDelegate.
    AppState.shared.appDelegate = self

    observeStatusItemVisibility()
    observeStatusItemTitle()
  }

  private func migrateHistorySourcesToAppOwnedZshOnly() {
    let existingSources = Defaults[.historySources]

    let removedSources = existingSources.filter { $0.url != HistorySource.retraceZshHistoryURL }
    if !removedSources.isEmpty {
      let removedPaths = removedSources.map(\.url.path).joined(separator: ", ")
      NSLog("Retrace migrated command history sources to app-owned zsh history and removed: %@", removedPaths)
    }

    Defaults[.historySources] = HistorySource.appOwnedZshSources
  }

  private func importUserZshHistoryIfNeeded() {
    guard !Defaults[.userZshHistoryImportAttempted] else { return }

    do {
      if try ZshIntegration.importUserHistoryIfPossible() {
        NSLog("Retrace imported existing ~/.zsh_history into app-owned zsh history")
        Task { @MainActor in
          await AppState.shared.history.reloadSources()
        }
      }
    } catch {
      NSLog("Retrace could not import existing ~/.zsh_history: %@", error.localizedDescription)
    }

    Defaults[.userZshHistoryImportAttempted] = true
  }

  private func observeStatusItemVisibility() {
    statusItemVisibilityObserver = observe(\.statusItem.isVisible, options: .new) { _, change in
      if let newValue = change.newValue, Defaults[.showInStatusBar] != newValue {
        Defaults[.showInStatusBar] = newValue
      }
    }

    Task { @MainActor in
      for await value in Defaults.updates(.showInStatusBar) {
        statusItem.isVisible = value
      }
    }
  }

  @MainActor
  private func observeStatusItemTitle() {
    updateStatusItemTitle()
    Task { @MainActor in
      for await value in Defaults.updates(.showRecentCommandInMenuBar) {
        if value {
          updateStatusItemTitle()
        } else {
          statusItem.button?.title = ""
        }
      }
    }
  }

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    panel = FloatingPanel(
      contentRect: NSRect(origin: .zero, size: Defaults[.windowSize]),
      identifier: Bundle.main.bundleIdentifier ?? "com.freeorz.retrace",
      statusBarButton: statusItem.button,
      onClose: { AppState.shared.popup.reset() }
    ) {
      ContentView()
    }

    showZshIntegrationPromptIfNeeded()
  }

  private func showZshIntegrationPromptIfNeeded() {
    guard ZshIntegration.shouldPromptForInstall(
      promptDismissed: Defaults[.zshIntegrationPromptDismissed],
      promptDeferredUntil: Defaults[.zshIntegrationPromptDeferredUntil]
    ) else {
      return
    }

    let alert = NSAlert()
    alert.messageText = localized("install_zsh_integration_message")
    alert.informativeText = localized("startup_zsh_integration_comment", ZshIntegration.displayHistoryPath)
    alert.alertStyle = .informational
    alert.addButton(withTitle: localized("install"))
    alert.addButton(withTitle: localized("not_now"))
    alert.addButton(withTitle: localized("dont_ask_again"))
    alert.addButton(withTitle: localized("copy_block"))

    let response = alert.runModal()
    switch response {
    case .alertFirstButtonReturn:
      ZshIntegrationUI.install(confirmFirst: false)
    case .alertSecondButtonReturn:
      Defaults[.zshIntegrationPromptDeferredUntil] = Date().addingTimeInterval(7 * 24 * 60 * 60)
    case .alertThirdButtonReturn:
      Defaults[.zshIntegrationPromptDismissed] = true
    case .alertFourthButtonReturn:
      ZshIntegrationUI.copyBlock()
    default:
      break
    }
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    Task { @MainActor in
      AppState.shared.footer.refreshHistoryActions()
      try? await AppState.shared.history.loadIfChanged()
      panel.toggle(height: AppState.shared.popup.height)
    }
    return true
  }

  @objc
  private func performStatusItemClick() {
    Task { @MainActor in
      AppState.shared.footer.refreshHistoryActions()
      try? await AppState.shared.history.loadIfChanged()
      panel.toggle(height: AppState.shared.popup.height, at: .statusItem)
    }
  }

  @MainActor
  func updateStatusItemTitle() {
    if Defaults[.showRecentCommandInMenuBar] {
      statusItem.button?.title = AppState.shared.menuBarCommandText
    }
  }

  private func localized(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
  }

  private func localized(_ key: String, _ arguments: CVarArg...) -> String {
    String(format: localized(key), arguments: arguments)
  }
}
