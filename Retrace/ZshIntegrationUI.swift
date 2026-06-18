import AppKit

enum ZshIntegrationUI {
  static func install(confirmFirst: Bool) {
    if confirmFirst, !confirmInstall() {
      return
    }

    do {
      try ZshIntegration.install()
      showResult(
        messageKey: "zsh_integration_installed_message",
        informativeTextKey: "zsh_integration_installed_comment"
      )
    } catch {
      showResult(
        messageKey: "zsh_integration_install_failed_message",
        informativeText: error.localizedDescription
      )
    }
  }

  static func copyBlock() {
    NSPasteboard.general.clearContents()
    if NSPasteboard.general.setString(ZshIntegration.block, forType: .string) {
      showResult(
        messageKey: "zsh_integration_copied_message",
        informativeTextKey: "zsh_integration_copied_comment"
      )
    } else {
      showResult(
        messageKey: "zsh_integration_copy_failed_message",
        informativeTextKey: "zsh_integration_copy_failed_comment"
      )
    }
  }

  static func clearRecordedHistory() {
    guard confirm(
      messageKey: "clear_retrace_history_message",
      informativeTextKey: "clear_retrace_history_comment",
      confirmTitleKey: "clear"
    ) else {
      return
    }

    do {
      try ZshIntegration.clearRecordedHistory()
      reloadHistorySources()
      showResult(
        messageKey: "retrace_history_cleared_message",
        informativeTextKey: "retrace_history_cleared_comment"
      )
    } catch {
      showResult(
        messageKey: "retrace_history_clear_failed_message",
        informativeText: error.localizedDescription
      )
    }
  }

  static func replaceRecordedHistoryWithUserHistory() {
    Task { @MainActor in
      let snapshot: ZshIntegration.UserHistorySnapshot
      do {
        snapshot = try await Task.detached {
          try ZshIntegration.userHistorySnapshot()
        }.value
      } catch {
        showResult(
          messageKey: "retrace_history_replace_failed_message",
          informativeText: error.localizedDescription
        )
        return
      }

      guard snapshot.hasContent else {
        showResult(
          messageKey: "retrace_history_replace_failed_message",
          informativeTextKey: "zsh_history_empty_comment"
        )
        return
      }

      guard confirm(
        messageKey: "replace_retrace_history_message",
        informativeText: localized("replace_retrace_history_comment", snapshot.commandCount),
        confirmTitleKey: "replace"
      ) else {
        return
      }

      do {
        try await Task.detached {
          try ZshIntegration.replaceRecordedHistory(with: snapshot.data)
        }.value
        reloadHistorySources()
        showResult(
          messageKey: "retrace_history_replaced_message",
          informativeTextKey: "retrace_history_replaced_comment"
        )
      } catch {
        showResult(
          messageKey: "retrace_history_replace_failed_message",
          informativeText: error.localizedDescription
        )
      }
    }
  }

  static func deleteRecordedHistory() {
    guard confirm(
      messageKey: "delete_retrace_history_message",
      informativeTextKey: "delete_retrace_history_comment",
      confirmTitleKey: "delete"
    ) else {
      return
    }

    do {
      try ZshIntegration.deleteRecordedHistory()
      reloadHistorySources()
      showResult(
        messageKey: "retrace_history_deleted_message",
        informativeTextKey: "retrace_history_deleted_comment"
      )
    } catch {
      showResult(
        messageKey: "retrace_history_delete_failed_message",
        informativeText: error.localizedDescription
      )
    }
  }

  private static func confirmInstall() -> Bool {
    confirm(
      messageKey: "install_zsh_integration_message",
      informativeTextKey: "install_zsh_integration_comment",
      confirmTitleKey: "install"
    )
  }

  private static func confirm(
    messageKey: String,
    informativeTextKey: String,
    confirmTitleKey: String
  ) -> Bool {
    confirm(
      messageKey: messageKey,
      informativeText: localized(informativeTextKey, ZshIntegration.displayHistoryPath),
      confirmTitleKey: confirmTitleKey
    )
  }

  private static func confirm(
    messageKey: String,
    informativeText: String,
    confirmTitleKey: String
  ) -> Bool {
    let alert = NSAlert()
    alert.messageText = localized(messageKey)
    alert.informativeText = informativeText
    alert.alertStyle = .informational
    alert.addButton(withTitle: localized(confirmTitleKey))
    alert.addButton(withTitle: localized("cancel"))

    return alert.runModal() == .alertFirstButtonReturn
  }

  private static func showResult(messageKey: String, informativeTextKey: String) {
    showResult(messageKey: messageKey, informativeText: localized(informativeTextKey, ZshIntegration.displayHistoryPath))
  }

  private static func showResult(messageKey: String, informativeText: String) {
    showResult(message: localized(messageKey), informativeText: informativeText)
  }

  private static func showResult(message: String, informativeText: String) {
    let alert = NSAlert()
    alert.messageText = message
    alert.informativeText = informativeText
    alert.alertStyle = .informational
    alert.addButton(withTitle: localized("ok"))
    alert.runModal()
  }

  private static func localized(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
  }

  private static func localized(_ key: String, _ arguments: CVarArg...) -> String {
    String(format: localized(key), arguments: arguments)
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
