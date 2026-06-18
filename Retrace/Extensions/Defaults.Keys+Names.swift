import AppKit
import Defaults

extension Defaults.Keys {
  static let highlightMatch = Key<HighlightMatch>("highlightMatch", default: .bold)
  static let lastReviewRequestedAt = Key<Date>("lastReviewRequestedAt", default: Date.now)
  static let numberOfUsages = Key<Int>("numberOfUsages", default: 0)
  static let pinnedCommands = Key<[String]>("pinnedCommands", default: [])
  static let popupPosition = Key<PopupPosition>("popupPosition", default: .cursor)
  static let popupScreen = Key<Int>("popupScreen", default: 0)
  static let searchMode = Key<Search.Mode>("searchMode", default: .exact)
  static let showFooter = Key<Bool>("showFooter", default: true)
  static let showInStatusBar = Key<Bool>("showInStatusBar", default: true)
  static let showRecentCommandInMenuBar = Key<Bool>("showRecentCommandInMenuBar", default: false)
  static let showSearch = Key<Bool>("showSearch", default: true)
  static let searchVisibility = Key<SearchVisibility>("searchVisibility", default: .always)
  static let showSpecialSymbols = Key<Bool>("showSpecialSymbols", default: true)
  static let showTitle = Key<Bool>("showTitle", default: true)
  static let commandHistorySize = Key<Int>("commandHistorySize", default: 50)
  static let historySources = Key<[HistorySource]>("historySources", default: HistorySource.defaultSources)
  static let zshIntegrationPromptDismissed = Key<Bool>("zshIntegrationPromptDismissed", default: false)
  static let zshIntegrationPromptDeferredUntil = Key<Date>("zshIntegrationPromptDeferredUntil", default: .distantPast)
  static let windowSize = Key<NSSize>("windowSize", default: NSSize(width: 450, height: 800))
  static let windowPosition = Key<NSPoint>("windowPosition", default: NSPoint(x: 0.5, y: 0.8))
}
