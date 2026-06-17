import Defaults
import Foundation
import Observation

@Observable
class CommandHistoryItemDecorator: Identifiable, Hashable, HasVisibility {
  static func == (lhs: CommandHistoryItemDecorator, rhs: CommandHistoryItemDecorator) -> Bool {
    return lhs.id == rhs.id
  }

  let id = UUID()

  var title: String = ""
  var attributedTitle: AttributedString?

  var isVisible: Bool = true
  var showsRecordedAt: Bool
  var isSelected: Bool = false
  var shortcuts: [KeyShortcut] = []

  func hash(into hasher: inout Hasher) {
    // We need to hash title and attributedTitle, so SwiftUI knows it needs to update the view if they change.
    hasher.combine(id)
    hasher.combine(title)
    hasher.combine(attributedTitle)
  }

  private(set) var item: CommandHistoryItem

  init(_ item: CommandHistoryItem, shortcuts: [KeyShortcut] = [], showsRecordedAt: Bool = true) {
    self.item = item
    self.shortcuts = shortcuts
    self.showsRecordedAt = showsRecordedAt
    self.title = item.title
  }

  func highlight(_ query: String, _ ranges: [Range<String.Index>]) {
    guard !title.isEmpty else {
      attributedTitle = nil
      return
    }

    let displayText = title.shortened(to: 500)
    var attributedString = AttributedString(displayText)
    ShellSyntaxHighlighter.apply(&attributedString, for: displayText)

    if !query.isEmpty {
      for range in ranges {
        if let lowerBound = AttributedString.Index(range.lowerBound, within: attributedString),
           let upperBound = AttributedString.Index(range.upperBound, within: attributedString) {
          switch Defaults[.highlightMatch] {
          case .bold:
            attributedString[lowerBound..<upperBound].font = .bold(.body)()
          case .italic:
            attributedString[lowerBound..<upperBound].font = .italic(.body)()
          case .underline:
            attributedString[lowerBound..<upperBound].underlineStyle = .single
          default:
            attributedString[lowerBound..<upperBound].backgroundColor = .findHighlightColor
            attributedString[lowerBound..<upperBound].foregroundColor = .black
          }
        }
      }
    }

    attributedTitle = attributedString
  }
}
