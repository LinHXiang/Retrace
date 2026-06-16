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

  func applicationWillFinishLaunching(_ notification: Notification) { // swiftlint:disable:this function_body_length
    migrateUserDefaults()

    // Bridge FloatingPanel via AppDelegate.
    AppState.shared.appDelegate = self

    statusItemVisibilityObserver = observe(\.statusItem.isVisible, options: .new) { _, change in
      if let newValue = change.newValue, Defaults[.showInStatusBar] != newValue {
        Defaults[.showInStatusBar] = newValue
      }
    }

    Task {
      for await value in Defaults.updates(.showInStatusBar) {
        statusItem.isVisible = value
      }
    }

    synchronizeStatusItemTitle()
    Task {
      for await value in Defaults.updates(.showRecentCommandInMenuBar) {
        if value {
          statusItem.button?.title = AppState.shared.menuBarCommandText
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
      // Start 2.x from scratch.
      Defaults.reset(.migrations)

      // Inverse hide* configuration keys.
      Defaults[.showFooter] = !UserDefaults.standard.bool(forKey: "hideFooter")
      Defaults[.showSearch] = !UserDefaults.standard.bool(forKey: "hideSearch")
      Defaults[.showTitle] = !UserDefaults.standard.bool(forKey: "hideTitle")
      UserDefaults.standard.removeObject(forKey: "hideFooter")
      UserDefaults.standard.removeObject(forKey: "hideSearch")
      UserDefaults.standard.removeObject(forKey: "hideTitle")

      Defaults[.migrations]["2024-07-01-version-2"] = true
    }

    // The following defaults are not used in Retrace 2.x
    // and should be removed in 3.x.
    // - LaunchAtLogin__hasMigrated
    // - avoidTakingFocus
    // - saratovSeparator
    // - maxMenuItemLength
    // - maxMenuItems
  }

  @objc
  private func performStatusItemClick() {
    Task { @MainActor in
      try? await AppState.shared.history.loadIfChanged()
      panel.toggle(height: AppState.shared.popup.height, at: .statusItem)
    }
  }

  private func synchronizeStatusItemTitle() {
    _ = withObservationTracking {
      AppState.shared.menuBarCommandText
    } onChange: {
      DispatchQueue.main.async {
        if Defaults[.showRecentCommandInMenuBar] {
          self.statusItem.button?.title = AppState.shared.menuBarCommandText
        }
        self.synchronizeStatusItemTitle()
      }
    }
  }

}
