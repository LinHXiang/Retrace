import Foundation
import Defaults

class CommandHistoryItem {
  var recordedAt: Date = Date.now
  var title = ""
  var command: String?

  init(command: String? = nil) {
    self.command = command
  }

  func generateTitle() -> String {
    // 1k characters is trade-off for performance
    var title = displayText.shortened(to: 1_000)

    if Defaults[.showSpecialSymbols] {
      if let range = title.range(of: "^ +", options: .regularExpression) {
        title = title.replacingOccurrences(of: " ", with: "·", range: range)
      }
      if let range = title.range(of: " +$", options: .regularExpression) {
        title = title.replacingOccurrences(of: " ", with: "·", range: range)
      }
      title = title
        .replacingOccurrences(of: "\n", with: "⏎")
        .replacingOccurrences(of: "\t", with: "⇥")
    } else {
      title = title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    return title
  }

  var displayText: String {
    text?.isEmpty == false ? text ?? "" : title
  }

  var text: String? { command }
}
