import AppKit

enum ZshIntegrationUI {
  static func install(confirmFirst: Bool) {
    if confirmFirst, !confirmInstall() {
      return
    }

    do {
      try ZshIntegration.install()
      showResult(
        message: "zsh integration installed",
        informativeText: "Retrace updated ~/.zshrc."
      )
    } catch {
      showResult(
        message: "Could not install zsh integration",
        informativeText: error.localizedDescription
      )
    }
  }

  static func copyBlock() {
    NSPasteboard.general.clearContents()
    if NSPasteboard.general.setString(ZshIntegration.block, forType: .string) {
      showResult(
        message: "zsh integration copied",
        informativeText: "The zsh integration block is now on the clipboard."
      )
    } else {
      showResult(
        message: "Could not copy zsh integration",
        informativeText: "The clipboard did not accept the zsh integration block."
      )
    }
  }

  static func clearRecordedHistory() {
    guard confirm(
      message: "Clear Retrace command history?",
      informativeText: """
      This clears only:
      \(ZshIntegration.displayHistoryPath)

      Your ~/.zsh_history file is not changed.
      """,
      confirmTitle: "Clear"
    ) else {
      return
    }

    do {
      try ZshIntegration.clearRecordedHistory()
      reloadHistorySources()
      showResult(
        message: "Retrace command history cleared",
        informativeText: "\(ZshIntegration.displayHistoryPath) is now empty."
      )
    } catch {
      showResult(
        message: "Could not clear Retrace command history",
        informativeText: error.localizedDescription
      )
    }
  }

  static func deleteRecordedHistory() {
    guard confirm(
      message: "Delete Retrace command history file?",
      informativeText: """
      This deletes only:
      \(ZshIntegration.displayHistoryPath)

      Your ~/.zsh_history file is not changed. The zsh hook will recreate the Retrace file when a new command is recorded.
      """,
      confirmTitle: "Delete"
    ) else {
      return
    }

    do {
      try ZshIntegration.deleteRecordedHistory()
      reloadHistorySources()
      showResult(
        message: "Retrace command history file deleted",
        informativeText: "\(ZshIntegration.displayHistoryPath) was deleted."
      )
    } catch {
      showResult(
        message: "Could not delete Retrace command history file",
        informativeText: error.localizedDescription
      )
    }
  }

  private static func confirmInstall() -> Bool {
    confirm(
      message: "Install zsh integration?",
      informativeText: """
      Retrace will update ~/.zshrc with a small marked hook.

      The hook appends commands to:
      \(ZshIntegration.displayHistoryPath)
      """,
      confirmTitle: "Install"
    )
  }

  private static func confirm(
    message: String,
    informativeText: String,
    confirmTitle: String
  ) -> Bool {
    let alert = NSAlert()
    alert.messageText = message
    alert.informativeText = informativeText
    alert.alertStyle = .informational
    alert.addButton(withTitle: confirmTitle)
    alert.addButton(withTitle: "Cancel")

    return alert.runModal() == .alertFirstButtonReturn
  }

  private static func showResult(message: String, informativeText: String) {
    let alert = NSAlert()
    alert.messageText = message
    alert.informativeText = informativeText
    alert.alertStyle = .informational
    alert.addButton(withTitle: "OK")
    alert.runModal()
  }

  private static func reloadHistorySources() {
    Task { @MainActor in
      await AppState.shared.history.reloadSources()
    }
  }
}

extension NSApplication.ModalResponse {
  static var alertFourthButtonReturn: Self {
    Self(rawValue: alertThirdButtonReturn.rawValue + 1)
  }
}
