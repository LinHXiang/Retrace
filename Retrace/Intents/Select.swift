import AppIntents

struct Select: AppIntent, CustomIntentMigratedAppIntent {
  static let intentClassName = "SelectIntent"

  static var title: LocalizedStringResource = "Select Terminal Command"
  static var description = IntentDescription("""
  Selects a command in Retrace terminal command history and copies it to the system clipboard.
  """)

  static var parameterSummary: some ParameterSummary {
    Summary("Select Terminal Command \(\.$number)")
  }

  @Parameter(title: "Number", default: 1, requestValueDialog: "What is the number of the command?")
  var number: Int

  private let positionOffset = 1

  func perform() async throws -> some IntentResult & ReturnsValue<String> {
    let items = AppState.shared.history.items
    let index = number - positionOffset
    guard items.indices.contains(index) else {
      throw AppIntentError.notFound
    }

    let value = items[index].title
    await AppState.shared.history.select(items[index])

    return .result(value: value)
  }
}
