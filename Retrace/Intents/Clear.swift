import AppIntents
import Defaults

struct Clear: AppIntent, CustomIntentMigratedAppIntent {
  static let intentClassName = "ClearIntent"

  static var title: LocalizedStringResource = "Clear Terminal Command History"
  static var description = IntentDescription("Clears all Retrace terminal command history except for pinned commands.")

  static var parameterSummary: some ParameterSummary {
    Summary("Clear Terminal Command History")
  }

  func perform() async throws -> some IntentResult {
    if !Defaults[.suppressClearAlert] {
      try await requestConfirmation()
    }

    await AppState.shared.history.clear()
    return .result()
  }
}
