import AppKit
import Defaults
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate {
  private static let maxZshIntegrationAutoInstallAttempts = 3

  var panel: FloatingPanel<ContentView>!
  private var notificationAuthorizationGranted: Bool?

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

    scheduleZshIntegrationAutoInstallIfNeeded()
  }

  private func scheduleZshIntegrationAutoInstallIfNeeded() {
    guard !isRunningTests else { return }

    DispatchQueue.global(qos: .utility).async { [weak self] in
      self?.autoInstallZshIntegrationIfNeeded()
    }
  }

  private func autoInstallZshIntegrationIfNeeded() {
    migrateLegacyZshIntegrationPreferences()
    guard !Defaults[.zshIntegrationAutoInstallDisabled] else { return }

    let zshrcContents = ZshIntegration.zshrcContents()
    if zshrcContents.map(ZshIntegration.isInstalled(in:)) == true {
      Defaults[.zshIntegrationWasInstalled] = true
      Defaults[.zshIntegrationAutoInstallAttempts] = 0
      return
    }

    guard Defaults[.zshIntegrationAutoInstallAttempts] < Self.maxZshIntegrationAutoInstallAttempts else {
      return
    }

    guard ZshIntegration.shouldAutoInstall(
      zshrcContents: zshrcContents,
      wasInstalled: Defaults[.zshIntegrationWasInstalled]
    ) else {
      return
    }

    do {
      try ZshIntegration.install()
      Defaults[.zshIntegrationWasInstalled] = true
      Defaults[.zshIntegrationAutoInstallAttempts] = 0
      NSLog("Retrace installed zsh integration automatically")
      showNotification(
        title: localized("zsh_integration_installed_message"),
        informativeText: localized("zsh_integration_installed_comment")
      )
      DispatchQueue.main.async {
        AppState.shared.footer.refreshHistoryActions()
      }
    } catch {
      Defaults[.zshIntegrationAutoInstallAttempts] += 1
      NSLog("Retrace could not install zsh integration automatically: %@", error.localizedDescription)
      showNotification(
        title: localized("zsh_integration_install_failed_message"),
        informativeText: error.localizedDescription
      )
    }
  }

  private func migrateLegacyZshIntegrationPreferences() {
    guard Defaults[.zshIntegrationLegacyPromptDismissed] else { return }

    Defaults[.zshIntegrationAutoInstallDisabled] = true
    Defaults[.zshIntegrationLegacyPromptDismissed] = false
  }

  private func showNotification(title: String, informativeText: String) {
    DispatchQueue.main.async { [weak self] in
      self?.showNotificationOnMain(title: title, informativeText: informativeText)
    }
  }

  private func showNotificationOnMain(title: String, informativeText: String) {
    let center = UNUserNotificationCenter.current()

    if let notificationAuthorizationGranted {
      guard notificationAuthorizationGranted else { return }

      deliverNotification(title: title, informativeText: informativeText, center: center)
      return
    }

    center.getNotificationSettings { [weak self] settings in
      DispatchQueue.main.async {
        self?.handleNotificationSettings(
          settings,
          title: title,
          informativeText: informativeText,
          center: center
        )
      }
    }
  }

  private func handleNotificationSettings(
    _ settings: UNNotificationSettings,
    title: String,
    informativeText: String,
    center: UNUserNotificationCenter
  ) {
    switch settings.authorizationStatus {
    case .authorized, .provisional, .ephemeral:
      notificationAuthorizationGranted = true
      deliverNotification(title: title, informativeText: informativeText, center: center)
    case .notDetermined:
      center.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, error in
        DispatchQueue.main.async {
          if let error {
            NSLog("Retrace could not request notification authorization: %@", error.localizedDescription)
          }
          self?.notificationAuthorizationGranted = granted
          guard granted else { return }

          self?.deliverNotification(title: title, informativeText: informativeText, center: center)
        }
      }
    default:
      notificationAuthorizationGranted = false
    }
  }

  private func deliverNotification(
    title: String,
    informativeText: String,
    center: UNUserNotificationCenter
  ) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = informativeText

    let request = UNNotificationRequest(
      identifier: UUID().uuidString,
      content: content,
      trigger: nil
    )
    center.add(request) { error in
      if let error {
        NSLog("Retrace could not deliver notification: %@", error.localizedDescription)
      }
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

  private var isRunningTests: Bool {
    ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
      NSClassFromString("XCTestCase") != nil
  }
}
