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
    migrateUserDefaults()

    // Bridge FloatingPanel via AppDelegate.
    AppState.shared.appDelegate = self

    observeStatusItemVisibility()
    observeStatusItemTitle()
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
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    Task { @MainActor in
      try? await AppState.shared.history.loadIfChanged()
      panel.toggle(height: AppState.shared.popup.height)
    }
    return true
  }

  private func migrateUserDefaults() {
    if Defaults[.migrations]["2024-07-01-version-2"] != true {
      // Keep the old one-time migration flag so existing installs do not rerun it.
      Defaults.reset(.migrations)

      // Migrate old inverse hide* configuration keys.
      Defaults[.showFooter] = !UserDefaults.standard.bool(forKey: "hideFooter")
      Defaults[.showSearch] = !UserDefaults.standard.bool(forKey: "hideSearch")
      Defaults[.showTitle] = !UserDefaults.standard.bool(forKey: "hideTitle")
      UserDefaults.standard.removeObject(forKey: "hideFooter")
      UserDefaults.standard.removeObject(forKey: "hideSearch")
      UserDefaults.standard.removeObject(forKey: "hideTitle")

      Defaults[.migrations]["2024-07-01-version-2"] = true
    }
  }

  @objc
  private func performStatusItemClick() {
    Task { @MainActor in
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
}
