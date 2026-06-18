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

  private static func confirmInstall() -> Bool {
    let alert = NSAlert()
    alert.messageText = "Install zsh integration?"
    alert.informativeText = """
    Retrace will update ~/.zshrc with a small marked hook.

    The hook appends commands to:
    \(ZshIntegration.displayHistoryPath)
    """
    alert.alertStyle = .informational
    alert.addButton(withTitle: "Install")
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
}

extension NSApplication.ModalResponse {
  static var alertFourthButtonReturn: Self {
    Self(rawValue: alertThirdButtonReturn.rawValue + 1)
  }
}
