import Foundation
import AppIntents

struct Get: AppIntent, CustomIntentMigratedAppIntent {
  static let intentClassName = "GetIntent"

  static var title: LocalizedStringResource = "Get Command from Terminal History"
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

  func perform() async throws -> some IntentResult & ReturnsValue<HistoryItemAppEntity> {
    var item: HistoryItem?
    if selected {
      item = AppState.shared.navigator.selection.first?.item
    } else {
      let index = number - positionOffset
      if AppState.shared.history.items.count >= index {
        item = AppState.shared.history.items[index].item
      }
    }

    guard let item else {
      throw AppIntentError.notFound
    }

    let intentItem = HistoryItemAppEntity()
    intentItem.text = item.text

    return .result(value: intentItem)
  }
}
