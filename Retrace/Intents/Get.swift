import Foundation
import AppIntents

struct Get: AppIntent, CustomIntentMigratedAppIntent {
  static let intentClassName = "GetIntent"

  static var title: LocalizedStringResource = "Get Terminal Command"
  static var description = IntentDescription("""
  Gets a command from Retrace terminal command history.
  """)

  @Parameter(title: "Selected", default: true)
  var selected: Bool

  @Parameter(title: "Number", default: 1)
  var number: Int

  private let positionOffset = 1

  static var parameterSummary: some ParameterSummary {
    When(\.$selected, .equalTo, false) {
      Summary {
        \.$number
        \.$selected
      }
    } otherwise: {
      Summary {
        \.$selected
      }
    }
  }

  func perform() async throws -> some IntentResult & ReturnsValue<CommandHistoryItemAppEntity> {
    var item: CommandHistoryItem?
    if selected {
      item = AppState.shared.navigator.selectedCommandItem?.item
    } else {
      let index = number - positionOffset
      let items = AppState.shared.history.items
      if items.indices.contains(index) {
        item = items[index].item
      }
    }

    guard let item else {
      throw AppIntentError.notFound
    }

    let intentItem = CommandHistoryItemAppEntity()
    intentItem.text = item.text

    return .result(value: intentItem)
  }
}
